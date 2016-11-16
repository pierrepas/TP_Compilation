open Calc_ast
open Calc_typast
open Calc_type

let rec decor : Calc_ast.expr -> Calc_typast.expr =
  function
  | Calc_ast.Int n -> Int(tyVar (), n)
  | Calc_ast.Bin(e1,op,e2) -> Bin(tyVar (), decor e1, op, decor e2)
  | Calc_ast.Opp(e) -> Opp(tyVar (), decor e)
  | Calc_ast.Call(name, es) -> Call(tyVar (), name, List.map decor es)
  | Calc_ast.If(e0,e1,e2) -> If(tyVar (), decor e0, decor e1, decor e2)
  | Calc_ast.Def(name,e1,e2) -> Def(tyVar (), name, decor e1, decor2)
