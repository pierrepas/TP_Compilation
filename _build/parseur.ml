open Ast

let list sep elt = parseur
    i:elt is:{ STR(sep) i':elt -> i'}* -> i::is
let parser int = n:''[0-9]+''                    -> int_of_string n
let parser ident = id:''[a-zA-Z][a-zA-Z0-9]*''   -> id
let parser sum = e:prod -> e | e1:prod "+" e2:sum -> I_Bin(e1,Add,e2)
                            | e1:prod "-" e2:sum -> I_Bin(e1,Sum,e2)
    and prof = e:atom -> e | e1:atom "*" e2:prod->I_Bin(e1,Mul,e2)
                           | e1:atom "/" e2:prod->I_Bin(e1,Div,e2)
                           | "-" e:prod
and atom = n:int -> Int n -> e
 | name:ident args:{"(" (list "," sum) ")"}?[[]]   -> Call(name,args)
and top =
      e:sum -> e
    | e0:sum p:pred e0':sum "?" e1:top ":" e2:top -> If(e0,p,e0',e1,e2)
    | name:ident "=" e1:sum e2:top -> Def(name,e1,e2)
