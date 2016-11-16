include Llvm_opp

let version = ref (
  try
    let ch = Unix.open_process_in "llvm-config --version" in
    let str = input_line ch in
    ignore (Unix.close_process_in ch);
    List.map int_of_string Str.(split (regexp_string ".") str)
  with _ ->
    Printf.eprintf "Warning: can not guess llvm version, set manually.\n%!";
    [3;8;0] (* stupid guess *))

let v37 = [3;7]

(* une AST pour les types de LLVM (il en manque, comme les tableaux, vecteur, structures ...) *)
type llvm_type =
| Void
| Int of int       (* Int x = ix like Int 8 = i8, etc ... *)
| Half | Float | Double | LongDouble
| Ptr of llvm_type (* pointeur sur: Ptr (Int 8) = i8* *)
(* type des fonctions: le type du résultat et le type des arguments, avec le nom
   dans le code source pour produire du code plus lisible.
   Le booléen est vrai pour les fonctions avec un nombre variable d'arguments *)
| Fun of llvm_type * (string * llvm_type) list * bool
| Array of int * llvm_type
| Vector of int * llvm_type
| Struct of bool * llvm_type list
| Opaque
| Label

(* une valeur llvm: un type et une chaîne permettant d'accéder à la valeur
   Ex: { ty = Int 64; access = "123" }
       { ty = Ptr (Int 32); access = "%ptr" }
       { ty = Ptr (Int 8); access = "getelementptr([10 x i8], [10 x i8]* @cstr, i32 0, i32 0)" }
*)
type value = {
  ty : llvm_type;
  access : string
}

let int_cst size n = { ty = Int size; access = string_of_int n }
let sint_cst size n = { ty = Int size; access = n }
let bool_cst b = if b then int_cst 1 1 else int_cst 1 0
let char_cst c = int_cst 8 (Char.code c)
let double_cst f = { ty = Double; access = string_of_float f }
let shalf_cst sf = { ty = Half; access = sf }
let sfloat_cst sf = { ty = Float; access = sf }
let sdouble_cst sf = { ty = Double; access = sf }
let slongdouble_cst sf = { ty = LongDouble; access = sf }

(* environnement global pour compiler un fichier, doit être crée par [start_emit_file] *)
type genv = {
  (* Liste des symboles connus par type *)
  (* fonctions et constantes : nom source -> cible *)
  globals : (ident, value) Hashtbl.t;
  (* buffer pour les commandes au toplevel du fichier cible llvm *)
  global_block : Buffer.t;
  (* buffer pour les instructions dans la fonction main *)
  main_block : Buffer.t;
  (* table des noms globaux déjà utilisés *)
  gnames : (global,int) Hashtbl.t;
  (* table des noms déjà utilisés dans le main *)
  main_names : (ident,int) Hashtbl.t;
}

(* environnement local pour compiler du code, créer par [start_function] et [start_init_code] *)
type env = {
  genv : genv;
  (* variable locale : nom source -> nom cible *)
  locals : (ident, value) Hashtbl.t;
  (* block courant (celui on l'on ajoute des instructions maintenant) *)
  block : Buffer.t;
  (* le label du block courant, "" pour le premier bloc d'une fonction *)
  mutable current_label : string;
  (* table des noms locaux déjà utilisés *)
  names : (ident,int) Hashtbl.t;
}

let get_label env = { ty = Label; access = env.current_label }
let get_global env = env.genv
let search_local env id = Hashtbl.find env.locals id

let search_global genv id = Hashtbl.find genv.globals id

let new_aux names prefix =
  let n = try Hashtbl.find names prefix with Not_found -> -1 in
  let rec fn n =
    let res = if n < 0 then prefix else prefix ^ string_of_int n in
    if Hashtbl.mem names res then fn (n+1)
    else (Hashtbl.add names prefix (n+1); res)
  in fn n

(* generation d'un nom local (qui commence par %) *)
let new_local env (prefix:ident) : ident =
  new_aux env.names prefix

(* generation d'un nom global (qui commence par @) *)
let new_global genv (prefix:global) : global =
  new_aux genv.gnames prefix

(* generation d'un nom de label *)
let new_label =
  let c = ref 0 in
  (fun () -> incr c; "label" ^ string_of_int !c)

(* recupération de l'arité d'une fonction à partir de son type *)
let fun_arity v =
  match v.ty with
    Fun(_,l,var_args) -> List.length l, var_args
  | _ -> failwith "this is not a function"

(* idem pour le type du résultat *)
let fun_res_type  v =
  match v.ty with
    Fun(r,_,_) -> r
  | _ -> failwith "this is not a function"

(* fonction d'affichage des types *)
let rec print_type_full incall buffer = function
  | Void -> Printf.bprintf buffer "void"
  | Int n -> Printf.bprintf buffer "i%d" n
  | Half -> Printf.bprintf buffer "half"
  | Float -> Printf.bprintf buffer "float"
  | Double -> Printf.bprintf buffer "double"
  | LongDouble -> Printf.bprintf buffer "fp128"
  | Ptr ty -> Printf.bprintf buffer "%a*" print_type ty
  | Fun (ty, args, b) ->
    let star = if incall && !version >= v37 then "" else "*" in
    Printf.bprintf buffer "%a (%a%s)%s"
      print_type ty print_types (List.map snd args) (if b then ",..." else "") star
  | Label -> Printf.bprintf buffer "label"
  | Array(size, ty) -> Printf.bprintf buffer "[%d x %a]" size print_type ty
  | Vector(size, ty) -> Printf.bprintf buffer "<%d x %a>" size print_type ty
  | Struct(packed, tys) ->
    if packed then Printf.bprintf buffer "<{%a}>" print_types tys
    else Printf.bprintf buffer "<{%a}>" print_types tys
  | Opaque -> Printf.bprintf buffer "opaque"

and print_type t = print_type_full false t

and print_type_fun t = print_type_full true t

and print_types buffer = function
  | [] -> ()
  | [ty]-> print_type buffer ty
  | ty::tys -> Printf.bprintf buffer "%a, %a" print_type ty print_types tys

(* affichage des valeurs *)
let print_value_with_type buffer x =
  Printf.bprintf buffer "%a %s" print_type x.ty x.access

(* affichage des valeurs *)
let print_value_with_type_fun buffer x =
  Printf.bprintf buffer "%a %s" print_type_fun x.ty x.access

(* affichage des listes de valeurs *)
let rec print_args : Buffer.t -> value list -> unit = fun buffer -> function
  | [] -> ()
  | [x] -> Printf.bprintf buffer "%a" print_value_with_type x
  | x::l -> Printf.bprintf buffer "%a, %a" print_value_with_type x print_args l

(* émission d'un phi *)
let emit_phi env ls =
  let rec print_phis : Buffer.t -> (value * value) list -> unit = fun buffer -> function
    | [] -> ()
    | [x,y] -> Printf.bprintf buffer "[%s, %s]" x.access y.access
    | (x,y)::l -> Printf.bprintf buffer "[%s, %s],%a" x.access y.access print_phis l
  in
  let r = new_local env (ident "phi") in
  let ty = match ls with
      (x,_)::_ -> x.ty
    | _ -> failwith "empty phis ?"
  in
  Printf.bprintf env.block "   %s = phi %a %a\n" r print_type ty print_phis ls;
  { ty; access = r }

let emit_size_of env ty size =
  let r1 = new_local env (ident "size") in
  let r2 = new_local env (ident "size") in
  let ty' = Int size in
  if !version < v37 then
    Printf.bprintf env.block "   %s = getelementptr %a* null, i32 1\n" r1 print_type ty
  else
    Printf.bprintf env.block "   %s = getelementptr %a, %a* null, i32 1\n" r1
      print_type ty print_type ty;
  Printf.bprintf env.block "   %s = ptrtoint %a* %s to %a\n" r2
    print_type ty r1 print_type ty';
  { ty = ty'; access = r2 }

(* émission d'une opération binaire (avec types des deux arguments = type du résultat *)
let emit_op_bin env instr e1 e2 =
  let instr = bin_to_string instr in
  let r = new_local env (ident instr) in
  Printf.bprintf env.block "   %s = %s %a %s, %s\n" r instr
    print_type e1.ty e1.access e2.access;
  {ty = e1.ty; access = r}

(* émission d'une opération binaire (avec types des deux arguments = type du résultat *)
let emit_cast env cast e ty =
  let cast = cast_to_string cast in
  let r = new_local env (ident cast) in
  Printf.bprintf env.block "   %s = %s %a %s to %a\n" r cast
    print_type e.ty e.access print_type ty;
  {ty; access = r}


(* émission d'une comparaison entière *)
let emit_icmp env pred e1 e2 =
  let pred = icmp_to_string pred in
  let r = new_local env (ident pred) in
  Printf.bprintf env.block "   %s = icmp %s %a %s, %s\n" r pred
    print_type e1.ty e1.access e2.access;
  {ty = Int 1; access = r}

(* émission d'une comparaison entière *)
let emit_fcmp env pred e1 e2 =
  let pred = fcmp_to_string pred in
  let r = new_local env (ident pred) in
  Printf.bprintf env.block "   %s = fcmp %s %a %s, %s\n" r pred
    print_type e1.ty e1.access e2.access;
  {ty = Int 1; access = r}

(* émission d'un début de block *)
let emit_block env label =
  Printf.bprintf env.block " %s:\n" label;
  env.current_label <- "%"^label

(* émission d'un branchement conditionnel *)
let emit_cond_br env cmp ltrue lfalse =
  Printf.bprintf env.block "   br i1 %s, label %%%s, label %%%s\n" cmp.access ltrue lfalse

(* émission d'un branchement inconditionnel *)
let emit_br env label =
  Printf.bprintf env.block "   br label %%%s\n" label

(* émission d'un alloca *)
let emit_alloca env ?numElts ty =
  let r = new_local env (ident "alloc") in
  (match numElts with
  | None -> Printf.bprintf env.block "   %s = alloca %a, align 4\n" r print_type ty
  | Some v -> Printf.bprintf env.block "   %s = alloca %a, %a, align 4\n" r print_type ty print_value_with_type v);
  { ty = Ptr ty; access = r }

(* émission d'un load *)
let emit_load env g =
  let r = new_local env (ident "load") in
  let ty = match g.ty with
      Ptr x -> x
    | _ -> failwith "non pointer in emit_load"
  in
  if !version < v37 then
    Printf.bprintf env.block "   %s = load %a, align 4\n" r print_value_with_type g
  else
    Printf.bprintf env.block "   %s = load %a, %a, align 4\n" r
      print_type ty print_value_with_type g;
  { ty; access = r }

(* émission d'un store *)
let emit_store env v ptr =
  Printf.bprintf env.block "   store %a, %a, align 4\n"
    print_value_with_type v print_value_with_type ptr

let rec get_gep_type ty indexes = match ty, indexes with
  | _, [] -> Ptr ty
  | Struct(_,tys), ({ ty = Int 32; access }::ls) ->
     let ty = try List.nth tys (int_of_string access) with _ ->
       failwith "bad getelementptr on struct" in
     get_gep_type ty ls
  | (Ptr ty | Array(_, ty)), _::ls ->
    get_gep_type ty ls
  | _ -> failwith "bad getelementptr"

let emit_getelementptr env v indexes =
  let r = new_local env (ident "adr") in
  match v.ty, indexes with
  | Ptr ty, [{ ty = Vector(s as s',_)}]
  | Vector(s,Ptr ty), [{ ty = Vector(s', _)}]
  | Vector(s as s',Ptr ty), [_]  ->
     if s <> s' then failwith "distinct vector size in emit_getelementptr";
     if !version < v37 then
       Printf.bprintf env.block "   %s = getelementptr %a, %a\n" r
         print_value_with_type v print_args indexes
     else
       Printf.bprintf env.block "   %s = getelementptr %a, %a, %a\n" r
         print_type ty print_value_with_type v print_args indexes;
     { ty = Vector(s,ty); access = r }
  | Ptr ty, _ ->
     if !version < v37 then
       Printf.bprintf env.block "   %s = getelementptr %a, %a\n" r
         print_value_with_type v print_args indexes
     else
       Printf.bprintf env.block "   %s = getelementptr %a, %a, %a\n" r
         print_type ty print_value_with_type v print_args indexes;
     let ty = get_gep_type v.ty indexes in
    { ty; access = r }
  | _ -> failwith "non pointer in emit_getelementptr"

let emit_offset_of env ty indexes size =
  let r1 = new_local env (ident "size") in
  let r2 = new_local env (ident "size") in
  let ty2 = get_gep_type ty indexes in
  let ty' = Int size in
  let ty0 = match ty with
    | Ptr t -> t
    | _ -> failwith "non pointer in emit_offset_of"
  in
  if !version < v37 then
    Printf.bprintf env.block "   %s = getelementptr %a null, %a\n" r1
      print_type ty print_args indexes
  else
    Printf.bprintf env.block "   %s = getelementptr %a, %a null, %a\n" r1
      print_type ty0 print_type ty print_args indexes;
  Printf.bprintf env.block "   %s = ptrtoint %a %s to %a\n" r2 print_type ty2 r1 print_type ty';
  { ty = ty'; access = r2 }

(* émission d'un call *)
let emit_call env fn args =
  let _, var_args = fun_arity fn in
  let ty = fun_res_type fn in
  let r = new_local env (ident "call") in
  if ty = Void then (
    if var_args then
      Printf.bprintf env.block "   call %a(%a)\n" print_value_with_type_fun fn print_args args
    else
      Printf.bprintf env.block "   call %a %s(%a)\n" print_type ty fn.access print_args args)
  else (
    if var_args then
      Printf.bprintf env.block "   %s = call %a(%a)\n" r print_value_with_type_fun fn print_args args
    else
      Printf.bprintf env.block "   %s = call %a %s(%a)\n" r print_type ty fn.access print_args args);
  { ty; access = r }

(* émission d'un return *)
let emit_ret env r =
  Printf.bprintf env.block "   ret %a\n" print_value_with_type r

(* émission d'un unreachable *)
let emit_unreachable env =
  Printf.bprintf env.block "   unreachable\n"

(* déclaration d'une fonction extern (@printf, ...), le nom doit comporter l'@ *)
let declare_extern genv name res_ty ?(var_args=false) args_types =
  if Hashtbl.mem genv.globals name then
    failwith ("duplicate function: " ^ name);
  let ty = Fun(res_ty, List.map (fun v -> ("", v)) args_types,var_args) in
  Printf.bprintf genv.global_block "declare %a %s(%a%s) nounwind\n"
    print_type res_ty name print_types args_types (if var_args then ",..." else "");
  let res = {ty; access = name} in
  Hashtbl.add genv.globals name res;
  res

(* enregistrement d'une fonction dans l'environnement,
   ce n'est pas fait par la fonction start_function, car
   pour les fonctions récursives mutuelles, on doit le faire avant *)
let register_function genv name res_type ?(var_args=false) args =
  let name' = new_global genv name in
  if Hashtbl.mem genv.globals name then
    failwith ("duplicate function: " ^ name);
  let ty = Fun(res_type, args,var_args) in
  let res = {ty; access = name'} in
  Hashtbl.add genv.globals name res;
  res

(* début de l'émission du code d'une fonction *)
let start_function genv src_name =
  let fn = try search_global genv src_name with Not_found ->
    failwith "start function used with undeclared function"
  in
  let block = Buffer.create 100 in
  let env = {
    genv = genv;
    current_label = "";
    locals = Hashtbl.create 31;
    block = block;
    names = Hashtbl.create 31
  }
  in
  let name = fn.access in
  let args, params_cible, var_args = match fn.ty with
      Fun(_,l,var_args) -> l, List.map (fun (name, ty) -> { ty; access = new_local env name }) l, var_args
    | _ -> failwith "non function in start_function"
  in
  List.iter2 (fun (name, _) v -> Hashtbl.add env.locals name v) args params_cible;
  let ty = fun_res_type fn in
  Printf.bprintf env.block ";%s\ndefine %a %s(%a%s) {\n" src_name print_type ty name print_args params_cible (if var_args then ",..." else "");
  env

(* fin de l'émission du code d'une fonction *)
let end_function env =
  Printf.bprintf env.block "}\n\n";
  Buffer.add_buffer env.genv.global_block env.block

(* début d'émissions de code pour la fonction main *)
let start_init_code genv =
  let block = Buffer.create 100 in
  {
    genv = genv;
    current_label = "";
    locals = Hashtbl.create 31;
    block = block;
    names = genv.main_names;
  }

(* fin d'émission de code pour la fonction main *)
let end_init_code env =
  Buffer.add_buffer env.genv.main_block env.block

(* conversion chaîne -> constante chaîne llvm *)
let string_to_llvm str =
  let len = String.length str in
  let b = Buffer.create (2 * String.length str) in
  for i = 0 to len - 1 do
    let code = Char.code str.[i] in
    if code < 32 || code >= 128 then
      Printf.bprintf b "\\%02x" code
    else
      Printf.bprintf b "%c" str.[i]
  done;
  Printf.bprintf b "\\00";
  Buffer.contents b, len + 1

(* déclaration d'une variable globale *)
let declare_global genv name ty init =
  let name' = new_global genv name in
  Printf.bprintf genv.global_block ";%s\n%s = global %a %s, align 4\n\n" name name' print_type ty init;
  let res = {ty = Ptr ty; access = name'} in
  Hashtbl.add genv.globals name res;
  res

(* déclaration d'une constante de type chaîne *)
let declare_string_constant genv name str =
  let str, len = string_to_llvm str in
  let name' = new_global genv name in
  Printf.bprintf genv.global_block ";%s\n%s = constant [%d x i8] c\"%s\"\n\n" name name' len str;
  let prefix = if !version < v37 then "" else Printf.sprintf "[%d x i8], " len in
  let access = Printf.sprintf "getelementptr(%s[%d x i8]* %s, i32 0, i32 0)" prefix len name' in
  let res = {ty = Ptr (Int 8); access} in
  Hashtbl.add genv.globals name res;
  res

let emit_in_scope env defs fn =
  List.iter (fun (name, value) -> Hashtbl.add env.locals name value) defs;
  let res = fn () in
  List.iter (fun (name, value) -> Hashtbl.remove env.locals name) defs;
  res

(* fonction pour démarrer l'emission d'un fichier .ll *)
let start_emit_file () =
  let genv = {
    globals = Hashtbl.create 31;
    global_block = Buffer.create 100;
    main_block = Buffer.create 100;
    gnames = Hashtbl.create 31;
    main_names = Hashtbl.create 31;
  }
  in
  Printf.bprintf genv.main_block "define i32 @main(i32 %%argc, i8** %%argv) {\n";
  genv

(* fonction terminant l'émission d'un fichier *)
let end_emit_file genv ch =
  Printf.bprintf genv.main_block "ret i32 0\n}\n";
  Buffer.output_buffer ch genv.global_block;
  Buffer.output_buffer ch genv.main_block

(* fonction d'affichage des types *)
let rec print_llvm_type buffer = function
  | Void -> Printf.fprintf buffer "void"
  | Int n -> Printf.fprintf buffer "i%d" n
  | Half -> Printf.fprintf buffer "half"
  | Float -> Printf.fprintf buffer "float"
  | Double -> Printf.fprintf buffer "double"
  | LongDouble -> Printf.fprintf buffer "fp128"
  | Ptr ty -> Printf.fprintf buffer "%a*" print_llvm_type ty
  | Fun (ty, args, b) ->
    Printf.fprintf buffer "%a (%a%s)*"
      print_llvm_type ty print_llvm_types (List.map snd args) (if b then ",..." else "")
  | Label -> Printf.fprintf buffer "label"
  | Array(size, ty) -> Printf.fprintf buffer "[%d x %a]" size print_llvm_type ty
  | Vector(size, ty) -> Printf.fprintf buffer "<%d x %a>" size print_llvm_type ty
  | Struct(packed, tys) ->
    if packed then Printf.fprintf buffer "<{%a}>" print_llvm_types tys
    else Printf.fprintf buffer "<{%a}>" print_llvm_types tys
  | Opaque -> Printf.fprintf buffer "opaque"

and print_llvm_types buffer = function
  | [] -> ()
  | [ty]-> print_llvm_type buffer ty
  | ty::tys -> Printf.fprintf buffer "%a, %a" print_llvm_type ty print_llvm_types tys
