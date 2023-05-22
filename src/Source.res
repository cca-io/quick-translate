open DataSheet

type t = DataSheet.data

let make = (data: array<Message.t>, fileName): t => {
  let headerRows = [
    [
      Cell.makeRO("ID"),
      Cell.makeRO("Description"),
      Cell.makeRO(fileName->FileUtils.fileNameWithoutExt),
    ],
  ]

  let rows =
    data->Array.map(({id, defaultMessage, description}) => [
      Cell.makeRO(id),
      Cell.make(~className="description", description->Option.getWithDefault("")),
      Cell.make(defaultMessage),
    ])

  Array.concat(headerRows, rows)
}

let add = (data: t, target: array<Message.t>, fileName) => {
  let targetMap =
    target
    ->Array.map(({Message.id: id, defaultMessage}) => (id, defaultMessage))
    ->Belt.Map.String.fromArray

  let header =
    data[0]->Option.mapWithDefault([], header =>
      header->Array.concat([Cell.makeRO(fileName->FileUtils.fileNameWithoutExt)])
    )

  let body =
    data
    ->Array.sliceToEnd(~start=1)
    ->Array.map(b => {
      let value =
        b[0]
        ->Option.flatMap(key => targetMap->Belt.Map.String.get(key.value))
        ->Option.mapWithDefault(Cell.empty(), value => Cell.make(value))

      b->Array.concat([value])
    })

  [header]->Array.concat(body)
}

let addMultiple = (data: t, targets: array<(string, array<JSON.t>)>) => {
  targets->Array.reduce(data, (newData, (fileName, target)) =>
    newData->add(target->Message.fromJson, fileName)
  )
}

let fromCsv = rows => {
  let header = rows[0]->Option.mapWithDefault([], hd => hd->Array.map(value => Cell.makeRO(value)))

  let body =
    rows
    ->Array.sliceToEnd(~start=1)
    ->Array.map(row =>
      row->Array.mapWithIndex((text, i) => i > 0 ? text->Cell.make : text->Cell.makeRO)
    )

  [header]->Array.concat(body)
}

let getColIndex = (data: t, column) =>
  data[0]->Option.getWithDefault([])->Belt.Array.getIndexBy(col => col.value === column)

let remove = (data: t, column: string) => {
  let colIndex = getColIndex(data, column)

  switch colIndex {
  | Some(index) =>
    data->Array.map(row =>
      row
      ->Array.mapWithIndex((col, i) => index === i ? None : Some(col))
      ->Array.filterMap(col => col)
    )
  | None => data
  }
}

let update = (data: t, changes: array<Change.t>): t => {
  // Needed in order to not mutate the state.
  let copy = data->Array.map(inner => inner->Array.copy)

  changes->Array.forEach(change => copy->DataSheet.update(change))
  copy
}

let empty = () => []

let getColData = (data: t, column: string) => {
  let colIndex = getColIndex(data, column)
  let body = data->Array.sliceToEnd(~start=1)

  switch colIndex {
  | Some(index) =>
    body->Array.filterMap(row =>
      switch (row[0], row[1], row[index]) {
      | (Some(key), Some(desc), Some(source)) =>
        Message.make(
          ~description=?desc.value->String.length > 0 ? Some(desc.value) : None,
          key.value,
          source.value,
        )->Some
      | _ => None
      }
    )

  | None => []
  }
}
