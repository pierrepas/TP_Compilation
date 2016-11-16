open Ast

let list sep elt = parser
    i:elt is:{ STR(sep) i':elt -> i' }* -> i::is
