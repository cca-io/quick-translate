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

let fromCsv = str => {
  let rows = str->CSV.toArray
  let header = rows[1]->Option.mapWithDefault([], hd => hd->Array.map(Cell.makeRO))

  let body =
    rows
    ->Array.sliceToEnd(2)
    ->Array.map(row =>
      row->Array.mapWithIndex((i, text) => i > 0 ? text->Cell.make : text->Cell.makeRO)
    )

  [header]->Array.concat(body)
}

let getColIndex = (data: array<array<Cell.t>>, column) =>
  data[0]->Option.getWithDefault([])->Array.getIndexBy(col => col.value === column)

let remove = (data: array<array<Cell.t>>, column: string) => {
  let colIndex = getColIndex(data, column)

  switch colIndex {
  | Some(index) =>
    data->Array.map(row =>
      row->Array.mapWithIndex((i, col) => index === i ? None : Some(col))->Array.keepMap(col => col)
    )
  | None => data
  }
}

let update = (data, changes) => data->DataSheet.update(changes)

let empty = () => []

let getColData = (data: array<array<Cell.t>>, column: string) => {
  let colIndex = getColIndex(data, column)
  let body = data->Array.sliceToEnd(1)

  switch colIndex {
  | Some(index) =>
    body->Array.keepMap(row =>
      switch (row[0], row[index]) {
      | (Some(key), Some(source)) => {Message.id: key.value, defaultMessage: source.value}->Some
      | _ => None
      }
    )

  | None => []
  }
}
