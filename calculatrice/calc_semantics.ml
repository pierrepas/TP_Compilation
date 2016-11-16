open Calc_ast
open Calc_expr_sem
let rec run : env -> program -> env = fun env p ->
  match p with
  | []       -> env
  | instr::p ->
     let env =
       if instr.params = [] then begin
         (* evaluation si ce n'est pas une fonction *)
         let n = eval env instr.def in
         Printf.printf "%s = %d\n%!" instr.name n;
         { instr with def = Int n } :: env
       end else
         instr :: env
     in run env p
