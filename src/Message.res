type t = {id: string, defaultMessage: string}

external toJson: array<t> => Js.Json.t = "%identity"
external fromJson: array<Js.Json.t> => array<t> = "%identity"
