(* This is free and unencumbered software released into the public domain. *)

type t
val create : unit -> t
val load_code : t -> string -> unit
val load_file : t -> string -> unit
val eval_code : t -> string -> unit
val eval_file : t -> string -> unit
val get_string : t -> string -> string
