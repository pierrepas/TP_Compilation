(* version de llvm.
   Guessed, if possible by llvm-config --version.
   partially tested from 3.5 to 4.0
*)
val version : int list ref


type label  (* un label llvm, "%" ajouté par la fonction ci-dessus *)

type ident  (* un nom d'identifiant dans le programme source,
               "%" ajouté par la fonction ci-dessus  *)
type global (* un nom global llvm, "@" ajouté par la fonction ci-dessus *)


(* creation d'un label *)
val label  : string -> label
(* d'un identifiant *)
val ident  : string -> ident
(* ou d'un nom de globale *)
val global : string -> global


(* une AST pour les types de LLVM *)
type llvm_type =
| Void
| Int of int       (* Int x = ix like Int 8 = i8, etc ... *)
| Half | Float | Double | LongDouble (* LongDouble = fp128 *)
| Ptr of llvm_type (* pointeur sur: Ptr (Int 8) = i8* *)
(* type des fonctions: le type du résultat et le type des arguments,
   avec le nom dans le code source pour produire du code plus lisible.
   Le booléen est vrai pour les fonctions avec un nombre variable
   d'arguments *)
| Fun of llvm_type * (ident * llvm_type) list * bool
| Array of int * llvm_type  (* Array(5,Int 32) = [5 x i32] *)
| Vector of int * llvm_type (* Vector(5,Int 32) = <5 x i32> *)
| Struct of bool * llvm_type list (* Structure
                                     compacte si le booléen est vrai *)
| Opaque (* opaque structure *)
| Label  (* label *)

(* affichage d'un type llvm *)
val print_llvm_type : out_channel -> llvm_type -> unit


(* une valeur llvm: un type et une chaîne représentat la valeur
   Ex: [{ ty = Int 64; access = ... }]
       [{ ty = Ptr (Int 32); access = ... }]
       [{ ty = Ptr (Int 8); access = ...}]
   Il faut éviter de produire le champs access manuellement.
   Cela est nécessaire seulement dans certains cas *)
type value = {
  ty : llvm_type;
  access : string;
}

(* constantes: pour int_cst et sint_cst, le 1er argument est la taille *)
val int_cst : int -> int -> value
val sint_cst : int -> string -> value
val bool_cst : bool -> value
val char_cst : char -> value
val double_cst : float -> value
val shalf_cst : string -> value
val sfloat_cst : string -> value
val sdouble_cst : string -> value
val slongdouble_cst : string -> value

(* environnement global pour compiler un fichier,
   créé par [start_emit_file]

   Ex: let genv = start_emit_file () in
       ... code pour produire le source llvm ...
       end_emit_file genv stdout *)
type genv

(* fonction pour démarrer l'emission d'un fichier .ll *)
val start_emit_file : unit -> genv

(* fonction terminant l'émission d'un fichier,
   c'est à ce moment que l'on écrit le fichier *)
val end_emit_file : genv -> out_channel -> unit

(* déclaration d'une fonction externe (@printf, ...) *)
(* Ex: let putchar = declare_extern genv (global "putchar")
                                         (Int 32) [Int 32]
       let printf  = declare_extern genv (global "printf")
                         (Int 32) ~var_args:true [Ptr (Int 8)] *)
val declare_extern : genv -> global -> llvm_type -> ?var_args:bool ->
                                       llvm_type list -> value

(* enregistrement d'une fonction dans l'environnement,
   ce n'est pas fait par la fonction start_function, car
   pour les fonctions récursives mutuelles, on doit le faire avant.
   Cette fonction n'émet pas de code.
   On garde le nom des paramètres dans le code source pour que
   le code llvm produit soit plus lisible.

   Ex: let fib = register_function genv "fib" (Int 32) ["n", Int 32] *)
val register_function : genv -> global -> llvm_type -> ?var_args:bool ->
                                    (ident * llvm_type) list -> value

(* déclaration d'une variable globale, à partir d'une constante llvm

   Ex: let x = declare_global genv "x" [Int 32] "0"*)
val declare_global : genv -> global -> llvm_type -> string -> value

(* déclaration d'une constante de type chaîne avec sa valeur initiale

   Ex: let hello = declare_string_constant (global "hello") "hello world!"
*)
val declare_string_constant : genv -> global -> string -> value

(* environnement local pour compiler du code,
   créé par [start_function] et [start_init_code]

   Ex: let fib = register_function genv "fib" (Int 32) [Int 32] in
       let env = start_function genv "fib" in
       ... code pour émettre le corps de la fonction ...
       end_function env

       let env = start_init_code genv in
       ... code d'initialisation qui va dans main ...
       end_init_code env *)
type env

(* début de l'émission du code d'une fonction, il faut le nom de la
   fonction dans le source et c'est tout cas la fonction doit avoir
   été enregistrée par register_function avant dans l'environement.
*)
val start_function : genv -> global -> env

(* fin de l'émission du code d'une fonction *)
val end_function : env -> unit

(* début d'émissions de code pour la fonction main *)
val start_init_code : genv -> env

(* fin d'émission de code pour la fonction main *)
val end_init_code : env -> unit

(* récupération du label courant pour l'utiliser,
   probablement dans un phi plus tard *)
val get_label : env -> value

(* renvoie l'environnement global à partir de l'environnement local *)
val get_global : env -> genv

(* recherche d'un symbole local *)
val search_local : env -> ident -> value

(* recherche d'un symbole global *)
val search_global : genv -> global -> value

(* generation d'un nouveau nom de label *)
val new_label : unit -> label

(* recupération de l'arité d'une fonction à partir de son type
   (peut lève l'exception (Failure "this is not a function")).
   le booléen est vrai pour les fonctions à nombre variable d'arguments *)
val fun_arity : value -> int * bool

(* idem pour le type du résultat  (peut lever la même exception) *)
val fun_res_type : value -> llvm_type

(* émission d'une opération binaire
   (le type des deux arguments = type du résultat)

   Ex: let z = emit_ob_bin env LL_add x y in *)
type llvm_bin = (* opérateurs binaires: "add", ... *)
  | LL_add | LL_fadd | LL_sub | LL_fsub | LL_mul | LL_fmul
  | LL_udiv | LL_sdiv | LL_fdiv | LL_urem | LL_srem | LL_frem
  | LL_shl | LL_lshr | LL_ashr | LL_and | LL_or | LL_xor

val emit_op_bin : env -> llvm_bin -> value -> value -> value

(* émission d'une comparaison entière

   Ex: let test = emit_icmp env LL_ge x y in *)
type llvm_icmp = (* tests sur les entiers *)
  | LL_eq | LL_ne | LL_ugt | LL_ult | LL_uge | LL_ule
  | LL_sgt | LL_slt | LL_sge | LL_sle

val emit_icmp : env -> llvm_icmp -> value -> value -> value

(* émission d'une comparaison flottante

   Ex: let test = emit_fcmp env LL_oge x y in*)
type llvm_fcmp = (* tests sur les flottants *)
  | LL_false | LL_true | LL_ord | LL_uno
  | LL_oeq | LL_one | LL_ogt | LL_olt | LL_oge | LL_ole
  | LL_ueq | LL_une | LL_ugt | LL_ult | LL_uge | LL_ule

val emit_fcmp : env -> llvm_fcmp -> value -> value -> value

(* émission d'un cast

   Ex: let r = emit_cast env LL_bitcast r (type_to_llvm ty) in *)
type llvm_cast = (* conversion de type *)
  | LL_trunc | LL_zext | LL_sext | LL_fptrunc | LL_fpext
  | LL_fptoui | LL_fptosi | LL_uitofp | LL_sitofp
  | LL_ptrtoint | LL_inttoptr | LL_bitcast

val emit_cast : env -> llvm_cast -> value -> llvm_type -> value

(* émission d'un début de block, i.e.: label:

   Ex: let lbl = new_label () in
       emit_br env lbl;
       emit_block env lbl; *)
val emit_block : env -> label -> unit

(* émission d'un branchement conditionnel

   Ex: let test = emit_icmp env LL_sge x y in
       let ltrue = new_label () in
       let lfalse = new_label () in
       emit_cond_br env test ltrue lfalse;
       emit_block env ltrue;
       ...
       emit_block env lfalse; *)
val emit_cond_br : env -> value -> label -> label -> unit

(* émission d'un branchement inconditionnel *)
val emit_br : env -> label -> unit

(* émission d'un phi

   Ex: let x = emit_op_bin env LL_add y z
       let lblx = get_label env in
       ...
       let y = emit_op_bin env LL_add u v
       let lbly = get_label env in
       ...
       let z = emit_phi env [(x,lblx);(y,lbly)] *)
val emit_phi : env -> (value * value) list -> value

(* émission d'un sizeof

   le paramètre entier est la taille voulue pour
   l'entier résultat *)
val emit_size_of : env -> llvm_type -> int -> value

(* calcul d'un offset pour un pointeur sur une structure.
   le premier entier est l'index dans la structure,
   le second la taille de l'entier en résultat *)
val emit_offset_of : env -> llvm_type -> value list -> int -> value

(* émission d'un alloca (allocation sur la pile)

   Ex: let x = emit_alloca env Int32 in
       emit_store env (int_cst 32 0) x;

       let tbl = emit_alloca env ~numElts:16 Int32 in *)
val emit_alloca : env -> ?numElts:value -> llvm_type -> value

(* émission d'un load

   Ex: let x = emit_load env ptr in *)
val emit_load : env -> value -> value

(* émission d'un store, le pointeur est en second

   Ex: emit_store env x ptr; *)
val emit_store : env -> value -> value -> unit

(* émission d'un call

   Ex: let fn = search_global (get_global env) "fn" in
       let x = search_local env "x" in
       let y = search_local env "y" in
       let z = emit_call env fn [x; y] in *)
val emit_call : env -> value -> value list -> value

(* émission d'un return

   Ex: emit_ret res; *)
val emit_ret : env -> value -> unit

(* émission d'un unreachable *)
val emit_unreachable : env -> unit

(* [emit_in_scope env [(name1, val1); ...; ...] fn] appelle fn pour émettre du code
   dans un environnement étendu avec les définitions indiquées

   Ex: let z = emit_in_scope env [("x", x); ("y", y)]
                             (fun () ->  ....) in *)
val emit_in_scope : env -> (ident * value) list -> (unit -> 'a) -> 'a

(* [emit_getelementptr env value [value1;...;valueN]] emet
   une instruction getelementptr pour déférencer value avec
   les index value1 ... valueN

   Ex:
   let tbl = emit_alloca env ~numElts:2 Int32 in
   let addr0 = emit_getelementptr env tbl [(int_cst 32 0); (int_cst 32 0)] in
   let addr1 = emit_getelementptr env tbl [(int_cst 32 0); (int_cst 32 1)] in
   emit_store (int_cst 32 42) addr0;
   emit_store (int_cst 32 73) addr1; *)
val emit_getelementptr : env -> value -> value list -> value
