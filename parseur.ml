open Ast
open Decap 

let blank = blank_regexp ''\([ \t\n\r]*\|\([#].*\n\r\)\)*''

let list (sep:string) (elt: 'a grammar) : 'a list grammar = 
	parser i:elt is:{ STR(sep) i':elt -> i'}* -> i::is

let parser int : int grammar = n:''[0-9]+'' -> int_of_string n

let parser ident : string grammar = id:''[a-zA-Z][a-zA-Z0-9]*''   -> id

let parser top : expr grammar = sum
and sum : expr grammar = 
	| e:prod -> e
	| e1:sum "+" e2:prod -> Bin(e1,Add,e2)
    | e1:sum "-" e2:prod -> Bin(e1,Sub,e2)
    and prod : expr grammar = 
    | e:atom -> e
    | e1:prod "*" e2:atom->Bin(e1,Mul,e2)
    | e1:prod "/" e2:atom->Bin(e1,Div,e2)
    (* | "-" e:prod *)

and atom : expr grammar = 
 | n:int -> Int n 
 | v:ident -> Var v
 |  "(" e:top ")" -> e

let parser programme : programme grammar =
 | e:top ";" rest : programme -> Expr(e)::rest
 | id:ident "=" e:top ';' rest:programme -> Def(id,e)::rest
 | EMPTY -> []

(* ocamlbuild parseur.byte -pp pa_ocaml -pkg decap *)