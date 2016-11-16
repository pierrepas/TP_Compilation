open Calc_ast

(* l'environnement est une liste de définition *)
type env = def list
(* fonction pour définir une constante *)
let simple_def name n = { name; params = []; def = Int n }

(* sémantique *)
let pred = function Geq -> (>=) | Ge -> (>) | Ne -> (<>)
                  | Leq -> (<=) | Le -> (<) | Eq -> (=)
let bin  = function Add -> (+) | Sub -> (-) | Mul -> ( * ) | Div -> (/)

let rec eval (env:env) : expr -> int = function
| Int n      -> n
| Bin(n,p,m) -> bin p (eval env n) (eval env m)
| Opp(n)     -> - eval env n
| If(e0,p,e0',e1,e2) ->
    let e0 = eval env e0 and e0' = eval env e0' in
    eval env (if pred p e0 e0' then e1 else e2)
| Def(name,e1,e2) ->
    let e1 = eval env e1 in
    eval (simple_def name e1::env) e2
| Call(id, args) ->
    let f = List.find (fun d -> d.name = id) env in
    let args = List.map2 (fun name e -> simple_def name (eval env e))
                         f.params args in
    eval (args@env) f.def

(* evaluation du programme complet *)
let rec run : env -> program -> env = fun env p ->
  match p with
  | []       -> env
  | instr::p ->
     let env =
       if instr.params = [] then begin
         (* evaluation et affichage si ce n'est pas une fonction *)
         let n = eval env instr.def in
         Printf.printf "%s = %d\n%!" instr.name n;
         { instr with def = Int n } :: env
       end else
         instr :: env
     in run env p
