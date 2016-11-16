type llvm_bin =
  | LL_add | LL_fadd | LL_sub | LL_fsub | LL_mul | LL_fmul
  | LL_udiv | LL_sdiv | LL_fdiv | LL_urem | LL_srem | LL_frem
  | LL_shl | LL_lshr | LL_ashr | LL_and | LL_or | LL_xor

let bin_to_string = function
  | LL_add  -> "add"
  | LL_fadd -> "fadd"
  | LL_sub  -> "sub"
  | LL_fsub -> "fsub"
  | LL_mul  -> "mul"
  | LL_fmul -> "fmul"
  | LL_udiv -> "udiv"
  | LL_sdiv -> "sdiv"
  | LL_fdiv -> "fdiv"
  | LL_urem -> "urem"
  | LL_srem -> "srem"
  | LL_frem -> "frem"
  | LL_shl  -> "shl"
  | LL_lshr -> "lshr"
  | LL_ashr -> "ashr"
  | LL_and  -> "and"
  | LL_or   -> "or"
  | LL_xor  -> "xor"

type llvm_icmp =
  | LL_eq | LL_ne | LL_ugt | LL_ult | LL_uge | LL_ule
  | LL_sgt | LL_slt | LL_sge | LL_sle

let icmp_to_string = function
  | LL_eq  -> "eq"
  | LL_ne  -> "ne"
  | LL_ugt -> "ugt"
  | LL_ult -> "ult"
  | LL_uge -> "uge"
  | LL_ule -> "ule"
  | LL_sgt -> "sgt"
  | LL_slt -> "slt"
  | LL_sge -> "sge"
  | LL_sle -> "sle"

type llvm_fcmp =
  | LL_false | LL_true | LL_ord | LL_uno
  | LL_oeq | LL_one | LL_ogt | LL_olt | LL_oge | LL_ole
  | LL_ueq | LL_une | LL_ugt | LL_ult | LL_uge | LL_ule

let fcmp_to_string = function
  | LL_false -> "false"
  | LL_true  -> "true"
  | LL_ord   -> "ord"
  | LL_uno   -> "uno"
  | LL_oeq   -> "oeq"
  | LL_one   -> "one"
  | LL_ogt   -> "ogt"
  | LL_olt   -> "olt"
  | LL_oge   -> "oge"
  | LL_ole   -> "ole"
  | LL_ueq   -> "ueq"
  | LL_une   -> "une"
  | LL_ugt   -> "ugt"
  | LL_ult   -> "ult"
  | LL_uge   -> "uge"
  | LL_ule   -> "ule"

type llvm_cast =
  | LL_trunc | LL_zext | LL_sext | LL_fptrunc | LL_fpext
  | LL_fptoui | LL_fptosi | LL_uitofp | LL_sitofp
  | LL_ptrtoint | LL_inttoptr | LL_bitcast

let cast_to_string = function
  | LL_trunc    -> "trunc"
  | LL_zext     -> "zext"
  | LL_sext     -> "sext"
  | LL_fptrunc  -> "fptrunc"
  | LL_fpext    -> "fpext"
  | LL_fptoui   -> "fptoui"
  | LL_fptosi   -> "fptosi"
  | LL_uitofp   -> "uitofp"
  | LL_sitofp   -> "sitofp"
  | LL_ptrtoint -> "ptrtoint"
  | LL_inttoptr -> "inttoptr"
  | LL_bitcast  -> "bitcast"

type label  = string (* un label llvm: commence par % *)
type ident  = string (* un nom d'identifiant dans le programme source *)
type global = string (* un nom global llvm: commence par @ *)

let label s = "%" ^ s
let ident s = "%" ^ s
let global s = "@" ^ s
