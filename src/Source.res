open Belt
open DataSheet

let make = (data: array<Js.Json.t>, fileName): array<array<Cell.t>> => {
  data
  ->Message.fromJson
  ->Array.map(({id, defaultMessage}) => [Cell.makeRO(id), Cell.make(defaultMessage)])
  ->Array.concat([[Cell.makeRO("ID"), Cell.makeRO(fileName->FileUtils.fileNameWithoutExt)]], _)
}

let add = (target: array<Js.Json.t>, data: array<array<Cell.t>>, fileName) => {
  let targetMap =
    target
    ->Message.fromJson
    ->Array.map(({Message.id: id, defaultMessage}) => (id, defaultMessage))
    ->Map.String.fromArray

  let header =
    data[0]->Option.mapWithDefault([], header =>
      header->Array.concat([Cell.makeRO(fileName->FileUtils.fileNameWithoutExt)])
    )

  let body =
    data
    ->Array.sliceToEnd(1)
    ->Array.map(b => {
      let value =
        b[0]
        ->Option.flatMap(key => targetMap->Map.String.get(key.value))
        ->Option.mapWithDefault(Cell.empty(), value => Cell.make(value))

      b->Array.concat([value])
    })

  [header]->Array.concat(body)
}
