open Ast
open Parseur
open Def_parseur

let rec run : env -> programme -> env = fun env p ->
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
