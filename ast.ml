type ident = string                                 (* Variables *)

type opBin = Add | Sub | Mul | Div                  (* Opérateurs Binaires *)

type opUna = Inc | Dec | Opp                        (* Opérateurs Unaires *)

(* On sépare les expressions par types *)

type expr_float =
    | Float of float                                (* Constante *)
    | Bin of expr_float * opBin * expr_float        (* Opération *)
    | Una of expr_float * opUna                     (* Opération Unaire *)

type expr_int =
    | Int of int
    | Bin of expr_int * opBin * expr_int 
    | Una of expr_int * opUna

type def = { name   : ident;                        (* Nom de la variable *)
             def    : expr }

type instruction =
    | def
    | expr_int
    | expr_float
