open Calc_ast
open Llvm

(* choix du type pour les nombres manipulés par la calculatrice,
   il suffit de changer ces deux lignes pour changer la taille des entiers *)
let int_size = 64
let calc_type = Int int_size and type_format = "%lld"

(* compilation des opérations binaires *)
let rec bin_to_llvm (env:env) (op:opBin) (e1:expr) (e2:expr) : value =
  let instr = match op with
    | Add -> LL_add | Sub -> LL_sub | Mul -> LL_mul | div -> LL_sdiv in
  let e1 = expr_to_llvm env e1 in
  let e2 = expr_to_llvm env e2 in
  emit_op_bin env instr e1 e2

(* compilation d'une expression avec récupération de son label,
   pour utiliser avec emit_phi *)
and expr_to_llvm_with_label (env:env) (e:expr) : value * value =
  let r = expr_to_llvm env e in
  let lbl = get_label env in
  r, lbl

(* compilation d'une expression *)
and expr_to_llvm (env:env) : expr -> value = function
  | Int n -> (int_cst int_size n)
  | Bin (e1, op, e2) -> bin_to_llvm env op e1 e2
  | Opp e1 -> bin_to_llvm env Sub (Int 0) e1
  (* compilation d'une définition locale, emit_in_scope est
     fait pour ça *)
  | Def(name,e1,e2) ->
    let e1 = expr_to_llvm env e1 in
    emit_in_scope env [(ident name, e1)] (fun () ->
      expr_to_llvm env e2)

  | If(e0,p,e0',e1,e2) ->
    (* compilation du résultat du test "e0 p e0'" *)
    let e0 = expr_to_llvm env e0 in
    let e0' = expr_to_llvm env e0' in
    let p = match p with
      | Geq -> LL_sge | Ge -> LL_sgt | Ne -> LL_ne
      | Leq -> LL_sle | Le -> LL_slt | Eq -> LL_eq
    in
    let cmp = emit_icmp env p e0 e0' in
    (* on a besoin de trois blocs: cas vrai, cas faux et
       un bloc pour ce qui viendra après le test *)
    let ltrue = new_label () in
    let lfalse = new_label () in
    let ljoin = new_label () in
    (* le branchement conditionnel *)
    emit_cond_br env cmp ltrue lfalse;
    (* le cas vrai *)
    emit_block env ltrue;
    let e1 = expr_to_llvm_with_label env e1 in
    emit_br env ljoin;
    (* le cas faux *)
    emit_block env lfalse;
    let e2 = expr_to_llvm_with_label env e2 in
    emit_br env ljoin;
    (* le bloc final avec le phi pour joindre les deux cas *)
    emit_block env ljoin;
    emit_phi env [e1; e2]
  (* pour un call il y a trois cas *)
  | Call(id,es) ->
    if es = [] then
      try
	(* cas sans argument, variable locale, on a la valeur llvm
           dans l'environnement local *)
	search_local env (ident id)
      with Not_found -> try
	(* cas sans argument, variable globale, on a l'adresse llvm
	   dans l'environnement global, il faut un store en plus *)
	let g = search_global (get_global env) (global id) in
	emit_load env g
      with Not_found ->
	failwith ("Unbound variable: "^id)
    else
      try
	(* il y a des arguments, on cherche la fonction dans l'environnement global
	   et on construit le call, si le nombre d'argument est le bon *)
	let fn = search_global (get_global env) (global id) in
	let arity, _ = fun_arity fn in
	if List.length es <> arity then
	  failwith (Printf.sprintf "Using function %s with %d arguments (%d required)"
		      fn.access (List.length es) arity);
	let args = List.map (fun e -> expr_to_llvm env e) es in
	emit_call env fn args
      with Not_found ->
	failwith ("Unbound function: "^id)

(* compilation d'une définition, deux cas: variable globale ou fonction *)
let def_to_llvm genv def =
  let arity = List.length def.params in
  if arity = 0 then begin (* cas d'une déclaration de variable *)
    let globale, printf_cste =
      try (* On regarde si elle et une constante pour le printf sont déjà déclarées *)
	let globale = search_global genv (global def.name) in
	let printf_cste = search_global genv (global (def.name^"__printf_constant")) in
	globale, printf_cste
      with Not_found -> (* sinon on les déclare *)
	let globale = declare_global genv (global def.name) (calc_type) "0" in
	let printf_str = Printf.sprintf "%s = %s\n" def.name type_format in
	let printf_cste = declare_string_constant genv
          (global (def.name^"__printf_constant")) printf_str in
	globale, printf_cste
    in
    (* on emet maintenant le code affectant la variable globale dans le "main" *)
    let env = start_init_code genv in
    let r = expr_to_llvm env def.def in
    emit_store env r globale;
    let printf = try search_global genv (global "printf") with Not_found -> assert false in
    let _ = emit_call env printf [printf_cste; r] in
    end_init_code env
  end else begin
    (* pour les fonctions, on a juste à emmettre le code, en cherchant le  *)
    let env = start_function genv (global def.name) in
    let r = expr_to_llvm env def.def in
    emit_ret env r;
    end_function env
  end

let register_function genv def =
  if def.params <> [] then
    let arg_types = List.map (fun name -> (ident name, calc_type)) def.params in
    let _ = register_function genv (global def.name) calc_type arg_types in
    ()

let compile_to_llvm defs =
  let genv = start_emit_file () in
  let _ = declare_extern genv (global "printf") (Int 32) ~var_args:true [Ptr (Int 8)] in
  List.iter (register_function genv) defs;
  List.iter (def_to_llvm genv) defs;
  end_emit_file genv stdout
