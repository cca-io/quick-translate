open Belt
open DataSheet

let make = (data: array<Js.Json.t>, fileName): array<array<Cell.t>> => {
  data
  ->Message.fromJson
  ->Array.map(({id, defaultMessage}) => [Cell.makeRO(id), Cell.make(defaultMessage)])
  ->Array.concat([[Cell.makeRO("ID"), Cell.makeRO(fileName->FileUtils.fileNameWithoutExt)]], _)
}

