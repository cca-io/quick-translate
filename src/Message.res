open Stdlib

type t = {
  id: string,
  defaultMessage: string,
  description: option<string>,
}

let make = (id, ~description=?, defaultMessage) => {
  id: id,
  defaultMessage: defaultMessage,
  description: description,
}

external toJson: array<t> => Json.t = "%identity"
external fromJson: array<Json.t> => array<t> = "%identity"
