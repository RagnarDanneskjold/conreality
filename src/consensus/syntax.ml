(* This is free and unencumbered software released into the public domain. *)

open Prelude

module Exception = struct
  #include "syntax/exception.ml"
end

exception Error = Exception.Error

module Command = struct
  #include "syntax/command.ml"
end

module Token = struct
  #include "syntax/token.ml"
end

module Lexer = struct
  #include "syntax/lexer.ml"
end

module Parser = struct
  #include "syntax/parser.ml"
end

let is_keyword string =
  let keyword = String.lowercase string in
  Hashtbl.mem Lexer.keyword_table keyword

let keyword_to_token string =
  let keyword = String.lowercase string in
  Hashtbl.find Lexer.keyword_table keyword

let parse_from_lexbuf input =
  Parser.parse Lexer.lex input

let parse_from_channel input =
  Lexing.from_channel input |> parse_from_lexbuf

let parse_from_string input =
  Lexing.from_string input |> parse_from_lexbuf

let is_valid string =
  try (parse_from_string string |> ignore; true) with
  | Error _ | Parsing.Parse_error -> false

let lexbuf_to_list lexbuf =
  let rec consume input output =
    match Lexer.lex input with
    | Token.EOF -> output
    | token -> consume input (token :: output)
  in List.rev (consume lexbuf [])

let tokenize input =
  Lexing.from_string input |> lexbuf_to_list

let help_key_for input =
  let open Token in
  match tokenize input with
  | [] -> None
  | ABORT :: _      -> Some "abort"
  | DISABLE :: _    -> Some "disable"
  | ENABLE :: _     -> Some "enable"
  | FIRE :: _       -> Some "fire"
  | HOLD :: _       -> Some "hold"
  | JOIN :: _       -> Some "join"
  | LEAVE :: _      -> Some "leave"
  | PAN :: TO :: _  -> Some "pan to"
  | PAN :: _        -> Some "pan"
  | PING :: _       -> Some "ping"
  | RESUME :: _     -> Some "resume"
  | TILT :: TO :: _ -> Some "tilt to"
  | TILT :: _       -> Some "tilt"
  | TOGGLE :: _     -> Some "toggle"
  | TRACK :: _      -> Some "track"
  | _  -> None

let help_for input =
  match help_key_for input with
  | Some key -> Some (Hashtbl.find (Command.help ()) key)
  | None -> None
