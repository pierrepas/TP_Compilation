type ident = string                                 (* Variables *)

type opBin = Add | Sub | Mul | Div                  (* Opérateurs Binaires *)

type opUna = Inc | Dec | Opp                        (* Opérateurs Unaires *)

(* On sépare les expressions par types *)

type expr_float =
    | Float of float                                (* Constante *)
    | F_Bin of expr_float * opBin * expr_float        (* Opération *)
    | F_Una of expr_float * opUna                     (* Opération Unaire *)

type expr_int =
    | Int of int
    | I_Bin of expr_int * opBin * expr_int 
    | I_Una of expr_int * opUna

type expr =
    | E_int of expr_int 
    | E_float of expr_float

type def = { name   : ident;                        (* Nom de la variable *)
             def    : expr}

type instruction =
    | Def of ident * expr
    | I_int of expr_int
    | I_float of expr_float

type programme =
    | Inst of instruction
    | Programme of instruction * programme
