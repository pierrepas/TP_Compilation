open Ast
open Parseur
open Evaluateur

let parser definition =
    name:ident
    params:{"(" i:ident is:{ "," i':ident -> i'}* ")" -> i::is}?[[]]
    "=" def:top
        -> {name; params; def}

let parser program = definition*

(* caractères blancs : espaces etc... et # jusqu'à la fin de ligne *)
let blank = Decap.handle_exception (fun () ->
    let p = Decap.parse_channel program blank stdin in
    ignore (Calc_semantics.run [] p)) ()
