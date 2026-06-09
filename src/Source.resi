type t = DataSheet.data

let make: (array<Message.t>, string) => t

let add: (t, array<Message.t>, string) => t

let getOrphanedTargetIds: (t, array<Message.t>) => array<string>

let mergeTarget: (t, array<Message.t>, string) => t

let replaceTarget: (t, array<Message.t>, string) => t

let addMultiple: (t, array<(string, array<Message.t>)>) => t

let fromCsv: array<array<string>> => t

let hasColumn: (t, string) => bool

let remove: (t, string) => t

let update: (t, array<DataSheet.Change.t>) => t

let empty: unit => t

let getColData: (t, string) => array<Message.t>

let getIntlValidation: (t, int, int) => option<IntlValidation.t>

let getNumberOfUntranslatedSegments: (t, int) => int

let getNumberOfInvalidSegments: (t, int) => int

let getNextEmptyCell: (t, int, int) => int

let getFirstEmptyCell: (t, int) => int

let getNextInvalidCell: (t, int, int) => int

let getFirstInvalidCell: (t, int) => int

let getNextIssueCell: (t, int, int) => int

let getFirstIssueCell: (t, int) => int
