let make: (array<Message.t>, Js.String2.t) => array<array<DataSheet.Cell.t>>

let add: (
  array<Message.t>,
  array<array<DataSheet.Cell.t>>,
  Js.String2.t,
) => array<array<DataSheet.Cell.t>>

let addMultiple: (
  array<(string, array<Js.Json.t>)>,
  array<array<DataSheet.Cell.t>>,
) => array<array<DataSheet.Cell.t>>

let fromCsv: string => array<array<DataSheet.Cell.t>>
let remove: (array<array<DataSheet.Cell.t>>, string) => array<array<DataSheet.Cell.t>>
let update: (array<array<DataSheet.Cell.t>>, DataSheet.Change.t) => unit
let empty: unit => array<'a>
let getColData: (array<array<DataSheet.Cell.t>>, string) => array<Message.t>
