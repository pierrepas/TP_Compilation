type ident = string                                 (* Variables *)

type opBin = Add | Sub | Mul | Div                  (* Opérateurs Binaires *)

type opUna = Inc | Dec | Opp                        (* Opérateurs Unaires *)

(* On sépare les expressions par types *)

type expr =
    | Float of float                                (* Constante *)
    | Bin of expr * opBin * expr        (* Opération *)
    | Una of expr * opUna                     (* Opération Unaire *)
    | Int of int
    | Var of ident

type valeur =
	| V_Int of int
	| V_Float of float

type def = { name   : ident;                        (* Nom de la variable *)
             def    : expr}

type instruction =
    | Def of ident * expr
    | Expr of expr

type env = def list

type programme = instruction list
