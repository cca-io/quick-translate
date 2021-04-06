type t = array<array<DataSheet.Cell.t>>

let make: (array<Message.t>, Js.String2.t) => t

let add: (t, array<Message.t>, Js.String2.t) => t

let addMultiple: (t, array<(string, array<Stdlib.Json.t>)>) => t

let fromCsv: array<array<string>> => t
let remove: (t, string) => t
let update: (t, DataSheet.Change.t) => unit
let empty: unit => t
let getColData: (t, string) => array<Message.t>
