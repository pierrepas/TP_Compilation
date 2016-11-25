open Ast

let opBin : opBin -> (int -> int -> int) = 
	function Add -> ( + ) | Sub -> ( - )
        | Mul -> ( * ) | Div -> ( / )

let opUna : opUna -> (int -> int) = 
	function Inc -> (fun x -> x+1) 
	| Dec -> (fun x -> x-1) 
	| Opp -> (fun x -> -x)

let rec eval (programme : programme) : programme -> expr -> valeur = function
    | Int n -> n
    | Int(n,p,m) -> opBin p (eval programme n) (eval programme m)
    | Opp(n) -> - eval programme n
