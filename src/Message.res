type t = {id: string, defaultMessage: string, description: option<string>}

let make = (id, ~description=None, defaultMessage) => {
  id: id,
  defaultMessage: defaultMessage,
  description: description,
}

external toJson: array<t> => Js.Json.t = "%identity"
external fromJson: array<Js.Json.t> => array<t> = "%identity"
