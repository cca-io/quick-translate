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
      Cell.make(~className="description", description->Option.getOr("")),
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
    data[0]->Option.mapOr([], header =>
      header->Array.concat([Cell.makeRO(fileName->FileUtils.fileNameWithoutExt)])
    )

  let body =
    data
    ->Array.slice(~start=1, ~end=data->Array.length)
    ->Array.map(b => {
      let value =
        b[0]
        ->Option.flatMap(key => targetMap->Belt.Map.String.get(key.value))
        ->Option.mapOr(Cell.empty(), value => Cell.make(value))

      b->Array.concat([value])
    })

  [header]->Array.concat(body)
}

let getOrphanedTargetIds = (data: t, target: array<Message.t>) => {
  let sourceIds =
    data
    ->Array.slice(~start=1, ~end=data->Array.length)
    ->Array.filterMap(row => row[0]->Option.map(cell => cell.value))
    ->Belt.Set.String.fromArray

  target
  ->Array.map(message => message.Message.id)
  ->Array.filter(id => !(sourceIds->Belt.Set.String.has(id)))
}

let getColIndex = (data: t, column) =>
  data[0]->Option.getOr([])->Array.findIndexOpt(col => col.value === column)

let mergeTarget = (data: t, target: array<Message.t>, fileName) => {
  let column = fileName->FileUtils.fileNameWithoutExt
  let targetMap =
    target
    ->Array.map(({Message.id: id, defaultMessage}) => (id, defaultMessage))
    ->Belt.Map.String.fromArray

  switch getColIndex(data, column) {
  | Some(colIndex) =>
    data->Array.mapWithIndex((row, rowIndex) =>
      if rowIndex === 0 {
        row
      } else {
        row->Array.mapWithIndex((cell, cellIndex) =>
          if cellIndex === colIndex {
            switch row[0] {
            | Some(idCell) =>
              targetMap
              ->Belt.Map.String.get(idCell.value)
              ->Option.mapOr(cell, value => Cell.make(value))
            | None => cell
            }
          } else {
            cell
          }
        )
      }
    )
  | None => add(data, target, fileName)
  }
}

let replaceTarget = (data: t, target: array<Message.t>, fileName) => {
  let column = fileName->FileUtils.fileNameWithoutExt
  let targetMap =
    target
    ->Array.map(({Message.id: id, defaultMessage}) => (id, defaultMessage))
    ->Belt.Map.String.fromArray

  switch getColIndex(data, column) {
  | Some(colIndex) =>
    data->Array.mapWithIndex((row, rowIndex) =>
      if rowIndex === 0 {
        row
      } else {
        row->Array.mapWithIndex((cell, cellIndex) =>
          if cellIndex === colIndex {
            switch row[0] {
            | Some(idCell) =>
              targetMap
              ->Belt.Map.String.get(idCell.value)
              ->Option.mapOr(Cell.empty(), value => Cell.make(value))
            | None => cell
            }
          } else {
            cell
          }
        )
      }
    )
  | None => add(data, target, fileName)
  }
}

let addMultiple = (data: t, targets: array<(string, array<Message.t>)>) =>
  targets->Array.reduce(data, (newData, (fileName, target)) => newData->add(target, fileName))

let fromCsv = rows => {
  let header = rows[0]->Option.mapOr([], hd => hd->Array.map(value => Cell.makeRO(value)))

  let body =
    rows
    ->Array.slice(~start=1, ~end=rows->Array.length)
    ->Array.map(row =>
      row->Array.mapWithIndex((text, i) => i > 0 ? text->Cell.make : text->Cell.makeRO)
    )

  [header]->Array.concat(body)
}

let hasColumn = (data: t, column) => data->getColIndex(column)->Option.isSome

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
  let body = data->Array.slice(~start=1, ~end=data->Array.length)

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

let isEmptyCell = (cell: Cell.t) => cell.value->String.trim->String.length === 0

let getSourceColIndex = (data: t) =>
  switch data[0] {
  | Some(header) =>
    switch header[1] {
    | Some(cell) if cell.value->SourceUtils.isCommentColumn || cell.className === "description" => 2
    | _ => 1
    }
  | None => 1
  }

let getIntlValidation = (data: t, rowIndex, colIndex) => {
  let sourceColIndex = data->getSourceColIndex

  switch (data[rowIndex], colIndex > sourceColIndex) {
  | (Some(row), true) =>
    switch (row[sourceColIndex], row[colIndex]) {
    | (Some(source), Some(target)) if !(target->isEmptyCell) =>
      IntlValidation.validate(~source=source.value, ~target=target.value)
    | _ => None
    }
  | _ => None
  }
}

let isInvalidTranslationCell = (row, sourceColIndex, colIndex) =>
  switch (row[sourceColIndex], row[colIndex]) {
  | (Some(source), Some(target)) if !(target->isEmptyCell) =>
    IntlValidation.validate(~source=source.value, ~target=target.value)->Option.isSome
  | _ => false
  }

let getNumberOfUntranslatedSegments = (data: t, colIndex) =>
  data
  ->Array.filter(col => col[colIndex]->Option.mapOr(false, isEmptyCell))
  ->Array.length

let getNumberOfInvalidSegments = (data: t, colIndex) => {
  let sourceColIndex = data->getSourceColIndex

  colIndex > sourceColIndex
    ? data
      ->Array.slice(~start=1, ~end=data->Array.length)
      ->Array.filter(row => row->isInvalidTranslationCell(sourceColIndex, colIndex))
      ->Array.length
    : 0
}

let findNextBodyRow = (data, ~startRowIndex, ~predicate) => {
  let bodyLength = data->Array.length - 1

  if bodyLength <= 0 {
    -1
  } else {
    let currentBodyIndex =
      startRowIndex >= 1 && startRowIndex < data->Array.length ? startRowIndex - 1 : -1

    let rec loop = offset =>
      if offset > bodyLength {
        -1
      } else {
        let wrappedBodyIndex = (currentBodyIndex + offset) % bodyLength
        let rowIndex = 1 + wrappedBodyIndex

        switch data[rowIndex] {
        | Some(row) if predicate(row) => rowIndex
        | _ => loop(offset + 1)
        }
      }

    loop(1)
  }
}

let getNextEmptyCell = (data: t, colIndex, startRowIndex) =>
  data->findNextBodyRow(~startRowIndex, ~predicate=row =>
    row[colIndex]->Option.mapOr(false, target => !target.readOnly && target->isEmptyCell)
  )

let getFirstEmptyCell = (data: t, colIndex) => data->getNextEmptyCell(colIndex, 0)

let getNextInvalidCell = (data: t, colIndex, startRowIndex) => {
  let sourceColIndex = data->getSourceColIndex

  colIndex > sourceColIndex
    ? data->findNextBodyRow(~startRowIndex, ~predicate=row =>
        row->isInvalidTranslationCell(sourceColIndex, colIndex)
      )
    : -1
}

let getFirstInvalidCell = (data: t, colIndex) => data->getNextInvalidCell(colIndex, 0)

let getNextIssueCell = (data: t, colIndex, startRowIndex) => {
  let sourceColIndex = data->getSourceColIndex

  data->findNextBodyRow(~startRowIndex, ~predicate=row =>
    row[colIndex]->Option.mapOr(false, target =>
      !target.readOnly &&
        (
          target->isEmptyCell ||
          (colIndex > sourceColIndex && row->isInvalidTranslationCell(sourceColIndex, colIndex))
        )
    )
  )
}

let getFirstIssueCell = (data: t, colIndex) => data->getNextIssueCell(colIndex, 0)
