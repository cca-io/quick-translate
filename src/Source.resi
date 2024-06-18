type t = DataSheet.data

let make: (array<Message.t>, string) => t

let add: (t, array<Message.t>, string) => t

let addMultiple: (t, array<(string, array<JSON.t>)>) => t

let fromCsv: array<array<string>> => t

let remove: (t, string) => t

let update: (t, array<DataSheet.Change.t>) => t

let empty: unit => t

let getColData: (t, string) => array<Message.t>

let getNumberOfUntranslatedSegments: (t, int) => int

let getFirstEmptyCell: (t, int) => int
