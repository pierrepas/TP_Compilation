open Ast

let opBin = function Add -> (+) | Sub -> (-)
        | Mul (*) | Div (/)

let opUna = function Inc (++) | Dec (--) | Opp (-)

let rec eval (programme : programme) : expr -> int = function
    | Int n -> n
    | Float n -> n
    | F_Bin(n,p,m) -> opBin p (eval programme n) (eval programme m)
    | I_Bin(n,p,m) -> opBin p (eval programme n) (eval programme m)
    | Opp(n) -> eval programme n
    | Def of ident * expr
