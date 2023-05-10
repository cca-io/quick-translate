type t = {
  id: string,
  defaultMessage: string,
  description: option<string>,
}

let make = (id, ~description=?, defaultMessage) => {
  id,
  defaultMessage,
  description,
}

external toJson: array<t> => JSON.t = "%identity"
external fromJson: array<JSON.t> => array<t> = "%identity"
