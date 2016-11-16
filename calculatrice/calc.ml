open Calc_ast
open Calc_parser

(* caractères blancs : espaces etc ... et # jusqu'à la fin de ligne *)
let blank = Decap.blank_regexp ''\([ \t\n\r]*\|#[^\n]*\n\)*''

let _ = Decap.handle_exception (fun () ->
  let p = Decap.parse_channel program blank stdin in
  if (Array.length Sys.argv > 1 && Sys.argv.(1) = "-c") then
    Calc_llvm.compile_to_llvm p
  else
    ignore (Calc_semantics.run [] p)) ()
