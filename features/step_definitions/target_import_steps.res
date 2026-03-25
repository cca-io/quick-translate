let currentData: ref<option<Source.t>> = ref(None)

let getRequired = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some(value) => value
  | None => failwith(`Expected "${key}" in cucumber table row`)
  }

let getOptional = (dict, key) =>
  switch Dict.get(dict, key) {
  | Some("") | None => None
  | Some(value) => Some(value)
  }

let messagesFromTable = dataTable =>
  dataTable
  ->Cucumber.DataTable.hashes
  ->Array.map(row =>
    Message.make(
      getRequired(row, "id"),
      ~description=?getOptional(row, "description"),
      getRequired(row, "defaultMessage"),
    )
  )

let requireData = () =>
  switch currentData.contents {
  | Some(data) => data
  | None => failwith("Expected cucumber scenario data to be initialized")
  }

let cellValue = (data: Source.t, rowId, columnName) => {
  let header =
    switch data[0] {
    | Some(header) => header
    | None => failwith("Expected source data header row")
    }

  let colIndex =
    switch header->Array.findIndexOpt(cell => cell.value === columnName) {
    | Some(index) => index
    | None => failwith(`Column "${columnName}" not found`)
    }

  let row =
    data
    ->Array.slice(~start=1, ~end=data->Array.length)
    ->Array.find(row =>
      switch row[0] {
      | Some(cell) => cell.value === rowId
      | None => false
      }
    )

  switch row {
  | Some(row) =>
    switch row[colIndex] {
    | Some(cell) => cell.value
    | None => ""
    }
  | None => failwith(`Row "${rowId}" not found`)
  }
}

Cucumber.given2("a source file {string} with messages", (fileName, dataTable: Cucumber.DataTable.t) => {
  currentData := Some(Source.make(messagesFromTable(dataTable), fileName))
})

Cucumber.given2("an existing target file {string} with messages", (fileName, dataTable: Cucumber.DataTable.t) => {
  currentData := Some(Source.add(requireData(), messagesFromTable(dataTable), fileName))
})

Cucumber.when2(
  "I merge an imported target file {string} with messages",
  (fileName, dataTable: Cucumber.DataTable.t) => {
    currentData := Some(Source.mergeTarget(requireData(), messagesFromTable(dataTable), fileName))
  },
)

Cucumber.when2(
  "I replace an imported target file {string} with messages",
  (fileName, dataTable: Cucumber.DataTable.t) => {
    currentData := Some(Source.replaceTarget(requireData(), messagesFromTable(dataTable), fileName))
  },
)

Cucumber.then2("the target column {string} should contain", (columnName, dataTable: Cucumber.DataTable.t) => {
  dataTable
  ->Cucumber.DataTable.hashes
  ->Array.forEach(row => {
    let expectedValue = getRequired(row, "value")
    let actualValue = cellValue(requireData(), getRequired(row, "id"), columnName)

    if actualValue !== expectedValue {
      failwith(
        `Expected row "${getRequired(row, "id")}" in column "${columnName}" to be "${expectedValue}" but got "${actualValue}"`,
      )
    }
  })
})
