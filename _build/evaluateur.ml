open Ast

let bin_val  (f_int : int -> int -> int) 
             (f_float : float -> float -> float)
            : (valeur -> valeur -> valeur) = fun v1 v2 ->
            match (v1,v2) with
            | (V_Int n1, V_Int n2) -> V_Int (f_int n1 n2)
            | (V_Int n1, V_Float n2) -> V_Float (f_float (float n1) n2) 
            | (V_Float n1, V_Int n2) -> V_Float (f_float n1 (float n2)) 
            | (V_Float n1, V_Float n2) -> V_Float (f_float n1 n2)



let opBin : opBin -> (valeur -> valeur -> valeur) = 
	function  Add -> bin_val ( + ) ( +. ) 
			| Sub -> bin_val ( - ) ( -. )
            | Mul -> bin_val ( * ) ( *. )
            | Div -> bin_val ( / ) ( /. )

(* let opUna : opUna -> (valeur -> valeur) = 
	function Inc -> (fun x -> x+1) 
           | Dec -> (fun x -> x-1) 
	| Opp -> (fun x -> -x)
*)

(* let rec eval_expr : env -> expr -> valeur = fun env e -> *)
 (*   match e with *)

let rec eval_expr (env : env) (e: expr) : valeur = match e with
    | Int n -> V_Int n
    | Float n -> V_Float n
    | Bin(n,p,m) -> opBin p (eval_expr env n) (eval_expr env m)
    | Var id -> (List.find(fun def -> def.name = id) env).def
    (* | Una(n) -> - eval_expr env n *)

let _ =
  assert (eval_expr [] (Bin(Int 3,Add,Float 5.0)) = V_Float 8.0);
  assert (eval_expr [] (Bin(Int 3,Add,Float 5.0)) = V_Float 8.0)

let print_val ch v = 
  let open Printf in 
  match v with
  | V_Int n -> fprintf ch "%d" n
  | V_Float n -> fprintf ch "%f" n

let rec eval_programme (env:env) (prg:programme) : env =
  match prg with
  | [] -> env
  | Def(name,e) :: prg -> 
    let v = eval_expr env e in
    Printf.printf "%s = %a\n%!" name print_val v;
    let env = { name = name; def = v} :: env in
    eval_programme env prg 
  | Expr(e) :: prg -> 
    let v = eval_expr env e in
    Printf.printf "_ = %a\n%!" print_val v;
    eval_programme env prg 