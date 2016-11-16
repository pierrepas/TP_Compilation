(* Ast de la calculatrice *)
open Union_find
open Calc_type
open Calc_ast

type expr =
| Int of typ * int                 (* constante *)
| Bin of typ * expr * opBin * expr (* opération *)
| Opp of typ * expr                (* opposée   *)
| Call of typ * ident * expr list  (* appel à une def *)
| If of typ * expr * expr * expr   (* test *)
| Def of typ * ident * expr * expr (* local definition *)
type def = { name   : ident; (* nom du symbole *)
               params : ident list;  (* paramètres *)
	       typ    : typ;
               def    : expr } (* corps de la définition *)
type program = def list
