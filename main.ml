open Ast
open Parseur
open Evaluateur


(* caractères blancs : espaces etc... et # jusqu'à la fin de ligne *)
let _ = Decap.handle_exception (fun () ->
    let p = Decap.parse_channel programme blank stdin in
    let _ = eval_programme [] p in
    ()) ()

(* ocamlbuild main.byte -pp pa_ocaml -pkg decap *)
(* ./main.byte 
	Control D pour quitter *)

(* ex: x=12; 12;)