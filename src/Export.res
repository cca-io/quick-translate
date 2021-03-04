let dataToJson = (data, col) => {
  let colData = data->Source.getColData(col)->Message.toJson->Js.Json.stringifyWithSpace(2)

  "data:text/json;charset=utf-8," ++ Js.Global.encodeURIComponent(colData)
}

let makeCsvExportFileName = () => {
  let timestamp = Js.Date.make()->Js.Date.toISOString->Js.String2.split(".")
  let formatted =
    timestamp[0]->Js.String2.replace("T", "_")->Js.String2.replaceByRe(%re("/:/g"), "-")

  formatted ++ "-export.csv"
}

let dataToCsv = (data: array<array<DataSheet.Cell.t>>) => {
  let csvData =
    data
    ->Belt.Array.map(row =>
      row->Belt.Array.map(cell => `"${cell.value}"`)->Js.Array2.joinWith(CSV.separator)
    )
    ->Js.Array2.joinWith("\n")

  `data:text/csv;charset=utf-8,\uFEFF${Js.Global.encodeURI(csvData)}`
}
