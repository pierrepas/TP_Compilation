open Calc_ast
open Calc_parser

let parser definition =
  name:ident
  params:{"(" i:ident is:{ "," i':ident -> i'}* ")" -> i::is}?[[]]
  "=" def:top
    -> { name; params; def }

let parser program = definition*

(* caractères blancs : espaces etc ... et # jusqu'à la fin de ligne *)
let blank = EarleyStr.blank_regexp ''\([ \t\n\r]*\|#[^\n]*\n\)*''
let _ = Earley.handle_exception (fun () ->
  let p = Earley.parse_channel program blank stdin in
  ignore (Calc_semantics.run [] p)) ()
