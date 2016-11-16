open Calc_ast

(* quelques synonymes du type [string] pour rendre les types plus lisible *)
type label = string (* un label llvm: commence par % *)
type op_bin = string (* un opérateur binaire: "add", ... *)
type pred = string (* un prédicat de comparaison: "neq", "eq", ...*)
type src_name = string (* un nom d'identifiant dans le programme source *)
type llvm_global = string (* un nom global llvm: commence par @ *)

(* une AST pour les types de LLVM *)
type llvm_type =
| Void
| Int of int       (* Int x = ix like Int 8 = i8, etc ... *)
| Half | Float | Double | LongDouble (* LongDouble = fp128 *)
| Ptr of llvm_type (* pointeur sur: Ptr (Int 8) = i8* *)
(* type des fonctions: le type du résultat et le type des arguments, avec le nom
   dans le code source pour produire du code plus lisible.
   Le booléen est vrai pour les fonctions avec un nombre variable d'arguments *)
| Fun of llvm_type * (string * llvm_type) list * bool
| Array of int * llvm_type  (* Array(5,Int 32) = [5 x i32] *)
| Vector of int * llvm_type (* Vector(5,Int 32) = <5 x i32> *)
| Struct of bool * llvm_type list (* Structure (packed if the boolean is given *)
| Opaque (* opaque structure *)
| Label  (* label *)

(* une valeur llvm: un type et une chaîne permettant d'accéder à la valeur
   Ex: [{ ty = Int 64; access = "123" }]
       [{ ty = Ptr (Int 32); access = "%ptr" }]
       [{ ty = Ptr (Int 8); access = "getelementptr([10 x i8]* @cstr, i32 0, i32 0)" }]
*)
type value = {
  ty : llvm_type;
  access : string
}

(* environnement global pour compiler un fichier, doit être crée par [start_emit_file]

   exemple
   let genv = start_emit_file () in
   ... code pour produire le source llvm ...
   end_emit_file genv stdout
*)
type genv

(** fonctions manipulant les environnements globaux **)

(* fonction pour démarrer l'emission d'un fichier .ll *)
val start_emit_file : unit -> genv

(* fonction terminant l'émission d'un fichier, c'est à ce moment que l'on écrit le fichier *)
val end_emit_file : genv -> out_channel -> unit

(* déclaration d'une fonction externe (@printf, ...), le nom doit comporter l'@ *)
(* exemples:

   let putchar = declare_extern genv "@putchar" (Int 32) [Int 32]
   let printf = declare_extern genv "@printf" (Int 32) ~var_args:true [Ptr (Int 8)]
*)
val declare_extern : genv -> llvm_global -> llvm_type -> ?var_args:bool -> llvm_type list -> value

(* enregistrement d'une fonction dans l'environnement,
   ce n'est pas fait par la fonction start_function, car
   pour les fonctions récursives mutuelles, on doit le faire avant.
   Cette fonction n'émet pas de code.

   On garde le nombre des paramètres dans le code source pour que
   le code llvm produit soit plus lisible.

   exemple:
   let fib = register_function genv "fib" (Int 32) ["n", Int 32]
*)
val register_function : genv -> src_name -> llvm_type -> ?var_args:bool -> (string * llvm_type) list -> value

(* déclaration d'une variable globale, le dernier argument est une constante llvm

   exemple:
   let x = declare_global genv "x" [Int 32] "0"
*)
val declare_global : genv -> src_name -> llvm_type -> string -> value

(* déclaration d'une constante de type chaîne, le nom de la constante avec sa valeur

   exemple
   let hello = declare_string_constant "hello" "hello world!"
*)
val declare_string_constant : genv -> src_name -> string -> value

(* environnement local pour compiler du code, créé par [start_function] et [start_init_code]

   exemple:
   let fib = register_function genv "fib" (Int 32) [Int 32] in
   let env = start_function genv "fib" in
   ... code pour émettre le corps de la fonction ...
   end_function env

   let env = start_init_code genv in
   ... code d'initialisation qui va dans main ...
   end_init_code env
 *)
type env

(* début de l'émission du code d'une fonction, il faut le nom de la
   fonction dans le source et c'est tout cas la fonction doit avoir
   été enregistrée par register_function avant dans l'environement.
*)
val start_function : genv -> src_name -> env

(* fin de l'émission du code d'une fonction *)
val end_function : env -> unit

(* début d'émissions de code pour la fonction main *)
val start_init_code : genv -> env

(* fin d'émission de code pour la fonction main *)
val end_init_code : env -> unit

(* récupération du label courant pour l'utiliser, par exemple, dans un phi plus tard *)
val get_label : env -> value

(* renvoie l'environnement global à partir de l'environnement local *)
val get_global : env -> genv

(* recherche d'un symbole local *)
val search_local : env -> src_name -> value

(* recherche d'un symbole global *)
val search_global : genv -> src_name -> value

(* generation d'un nouveau nom de label *)
val new_label : unit -> label

(* recupération de l'arité d'une fonction à partir de son type (peut lever l'exception Failure) *)
val fun_arity : value -> int * bool (* le booléen est vrai pour les fonctions à nombre variable d'arguments *)

(* idem pour le type du résultat  (peut lever l'exception Failure) *)
val fun_res_type : value -> llvm_type

(* émission d'une opération binaire (avec types des deux arguments = type du résultat)

   exemple:
   let z = emit_ob_bin env "add" x y in
*)
val emit_op_bin : env -> op_bin -> value -> value -> value

(* émission d'une comparaison entière

   exemple:
   let test = emit_ob_bin env "sge" x y in
*)
val emit_icmp : env -> pred -> value -> value -> value

(* émission d'un début de block, i.e.: label:

   exemple:
   let lbl = new_label () in
   emit_br env lbl;
   emit_block env lbl;
*)
val emit_block : env -> label -> unit

(* émission d'un branchement conditionnel

   exemple:
   let test = emit_icmp env "sge" x y in
   let ltrue = new_label () in
   let lfalse = new_label () in
   emit_cond_br env test ltrue lfalse;
   emit_block env ltrue;
   ...
   emit_block env lfalse;
*)
val emit_cond_br : env -> value -> label -> label -> unit

(* émission d'un branchement inconditionnel *)
val emit_br : env -> label -> unit

(* émission d'un phi

   exemple:
   let x = emit_op_bin env "add" y z
   let lblx = get_label env in
   ...
   let y = emit_op_bin env "add" u v
   let lbly = get_label env in
   ...
   let z = emit_phi env [(x,lblx);(y,lbly)]
*)
val emit_phi : env -> (value * value) list -> value

(* émission d'un alloca (allocation sur la pile)

   exemple:
   let x = emit_alloca env Int32 in
   emit_store env { ty = Int 32; access = "0" } x;

   let tbl = emit_alloca env ~numElts:16 Int32 in
*)
val emit_alloca : env -> ?numElts:value -> llvm_type -> value

(* émission d'un load

   exemple:
   let x = emit_load env ptr in
*)
val emit_load : env -> value -> value

(* émission d'un store, le pointeur est en second

   exemple:
   emit_store env x ptr;
*)
val emit_store : env -> value -> value -> unit

(* émission d'un call

   exemple:
   let fn = search_global (get_global env) "fn" in
   let x = search_local env "x" in
   let y = search_local env "y" in
   let z = emit_call env fn [x; y] in
*)
val emit_call : env -> value -> value list -> value

(* émission d'un return

   exemple:
   emit_ret res;
*)
val emit_ret : env -> value -> unit

(* [emit_in_scope env [(name1, val1); ...; ...] fn] appelle fn pour émettre du code
   dans un environnement étendu avec les définitions indiquées

   exemple:
   let z =
     emit_in_scope env [("x", x); ("y", y)] (fun () ->
       ....)
   in
 *)
val emit_in_scope : env -> (src_name * value) list -> (unit -> 'a) -> 'a

(* [emit_getelementptr env value [value1;...;valueN]] emet
   une instruction getelementptr pour déférencer value avec
   les index value1 ... valueN

   exemple:
   let tbl = emit_alloca env ~numElts:2 Int32 in
   let addr0 = emit_getelementptr env tbl [{ ty = Int 32; access = "0" }; { ty = Int 32; access = "0" }] in
   let addr1 = emit_getelementptr env tbl [{ ty = Int 32; access = "0" }; { ty = Int 32; access = "1" }] in
   emit_store { ty = Int 32; access = "42" } addr0;
   emit_store { ty = Int 32; access = "73" } addr1;
*)
val emit_getelementptr : env -> value -> value list -> value
