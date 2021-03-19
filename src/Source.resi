type t = array<array<DataSheet.Cell.t>>

let make: (array<Message.t>, Js.String2.t) => t

let add: (array<Message.t>, t, Js.String2.t) => t

let addMultiple: (array<(string, array<Js.Json.t>)>, t) => t

let fromCsv: array<array<string>> => t
let remove: (t, string) => t
let update: (t, DataSheet.Change.t) => unit
let empty: unit => array<'a>
let getColData: (t, string) => array<Message.t>
