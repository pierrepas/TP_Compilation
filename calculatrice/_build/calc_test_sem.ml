open Calc_ast

let x = Call("x",[]) and y = Call("y",[]) and z = Call("z",[])
let test = [
  { name = "a"; params = []; def = Bin(Int 2, Add, Int 3) };
  { name = "f"; params = ["x";"y"];
    def = Bin(Bin(x,Mul,x),Add,Bin(y,Mul,y)) };
  { name = "g"; params = ["x";"y";"z"];
    def = Call("f", [Call("f",[x;y]) ; Call("f",[y;z]) ]) };
  { name = "b"; params = [];
    def = Call("f",[Call("a",[]);Call("a",[])]) };
  { name = "c"; params = [];
    def = Call("g",[Call("a",[]);Call("b",[]);Call("a",[])]) };
]
let _ = Calc_semantics.run [] test
