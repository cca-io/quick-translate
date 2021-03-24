open Stdlib
open DataSheet

type t = array<array<Cell.t>>

let make = (data: array<Message.t>, fileName): t => {
  data
  ->Array.map(({id, defaultMessage, description}) => [
    Cell.makeRO(id),
    Cell.make(~className="description", description->Option.getWithDefault("")),
    Cell.make(defaultMessage),
  ])
  ->Array.concat(
    [
      [
        Cell.makeRO("ID"),
        Cell.makeRO("Description"),
        Cell.makeRO(fileName->FileUtils.fileNameWithoutExt),
      ],
    ],
    _,
  )
}

let add = (target: array<Message.t>, data: t, fileName) => {
  let targetMap =
    target
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

let addMultiple = (targets: array<(string, array<Json.t>)>, data: t) => {
  targets->Array.reduce(data, (newData, (fileName, target)) =>
    target->Message.fromJson->add(newData, fileName)
  )
}

let fromCsv = rows => {
  let header = rows[0]->Option.mapWithDefault([], hd => hd->Array.map(value => Cell.makeRO(value)))

  let body =
    rows
    ->Array.sliceToEnd(1)
    ->Array.map(row =>
      row->Array.mapWithIndex((i, text) => i > 0 ? text->Cell.make : text->Cell.makeRO)
    )

  [header]->Array.concat(body)
}

let getColIndex = (data: t, column) =>
  data[0]->Option.getWithDefault([])->Array.getIndexBy(col => col.value === column)

let remove = (data: t, column: string) => {
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

let getColData = (data: t, column: string) => {
  let colIndex = getColIndex(data, column)
  let body = data->Array.sliceToEnd(1)

  switch colIndex {
  | Some(index) =>
    body->Array.keepMap(row =>
      switch (row[0], row[1], row[index]) {
      | (Some(key), Some(desc), Some(source)) =>
        Message.make(
          ~description=desc.value->String.length > 0 ? Some(desc.value) : None,
          key.value,
          source.value,
        )->Some
      | _ => None
      }
    )

  | None => []
  }
}
