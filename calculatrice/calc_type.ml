open Union_find

type btyp =
  | TyInt
  | TyBool
  | TyFun of typ list * typ
and typ = btyp link

exception Clash

let tyInt  = new_link TyInt
let tyBool = new_link TyBool
let tyFun args res = new_link (TyFun(args,res))
let tyVar () = fresh_link ()

let rec btyp_unif : btyp -> btyp -> unit =
  fun t1 t2 ->
    match t1, t2 with
    | TyInt , TyInt  -> ()
    | TyBool, TyBool -> ()
    | TyFun(args1,res1), TyFun(args2,res2) when List.length args1 = List.length args2 ->
      List.iter2 unif args1 args2;
      unif res1 res2
    | _ -> raise Clash

and unif : typ -> typ -> unit = fun t1 t2 -> union btyp_unif t1 t2
