open Belt
open ReactUtils

@react.component
let make = () => {
  let (data, setData) = React.useState(() => Source.empty())
  let (dragging, setDragging, onDragOver, onDragLeave) = Hooks.useDrag()

  let sourceAvailable = data->Array.length > 0

  let handleDrop = (e, fileType) => {
    e->cancelMouseEvent
    let files = e->File.fromMouseEvent

    if files->Array.length === 1 {
      switch (files[0], fileType) {
      | (Some(file), FileUtils.Source) if file->File.isJson =>
        File.read(file, result =>
          setData(_ =>
            result
            ->File.resultToJson
            ->Option.mapWithDefault(data, result => result->Source.make(file.name))
          )
        )

      | (Some(file), Source) if file->File.isCsv =>
        File.read(file, result => setData(_ => result->Source.fromCsv))

      | (Some(file), Target) if file->File.isJson =>
        File.read(file, result =>
          setData(_ =>
            result
            ->File.resultToJson
            ->Option.mapWithDefault(data, result => result->Source.add(data, file.name))
          )
        )

      | _ => ()
      }
    }

    setDragging(_ => false)
  }

  let onCreateTarget = _evt => {
    let lc = Window.prompt("Enter file name for target")

    lc->Option.forEach(lc => setData(_ => []->Source.add(data, lc)))
  }

  let onRemoveTarget = column => {
    let shallDelete = Window.confirm(`Delete column "${column}"?`)

    if shallDelete {
      setData(_ => data->Source.remove(column))
    }
  }

  let onRemoveSource = _evt => {
    let shallDelete = Window.confirm("Remove source?")

    if shallDelete {
      setData(_ => Source.empty())
    }
  }

  let onCellsChanged = changes => {
    let dataSheet = data->Array.copy

    changes->Array.forEach(change => dataSheet->Source.update(change))

    setData(_ => dataSheet)
  }

  let onExport = col => {
    let colData = data->Source.getColData(col)->Message.toJson->Js.Json.stringifyWithSpace(2)

    let uri = "data:text/json;charset=utf-8," ++ Js.Global.encodeURIComponent(colData)
    uri->FileUtils.download(~download={col ++ ".json"})
  }

  let onExportAll = _evt => {
    data[0]
    ->Option.getWithDefault([])
    ->Array.forEachWithIndex((i, cell) =>
      if i > 0 {
        onExport(cell.value)
      }
    )
  }

  let onExportCsv = _evt => {
    let csvData =
      data
      ->Array.map(row =>
        row->Array.map(cell => `"${cell.value}"`)->Js.Array2.joinWith(CSV.separator)
      )
      ->Js.Array2.joinWith("\n")

    let uri = `data:text/csv;charset=utf-8,\uFEFF${Js.Global.encodeURI(csvData)}`
    uri->FileUtils.download(~download={"export.csv"})
  }

  let sheetRenderer = (props: DataSheet.SheetProps.t) => {
    <table className={props.className}>
      <thead>
        <tr>
          {data[0]
          ->Option.getWithDefault([])
          ->Array.mapWithIndex((i, col) =>
            <th key={i->Int.toString}>
              {i > 0
                ? <>
                    <button onClick={evt => onExport(col.value)}> {"Export JSON"->s} </button>
                    {" "->s}
                    <button onClick={evt => onRemoveTarget(col.value)}> {"Remove"->s} </button>
                  </>
                : <button onClick={onRemoveSource}> {"Remove source"->s} </button>}
            </th>
          )
          ->React.array}
        </tr>
      </thead>
      <tbody> {props.children} </tbody>
    </table>
  }

  <div className="App" onDragOver>
    <Content sourceAvailable>
      <DataSheet data onCellsChanged sheetRenderer valueRenderer={cell => cell.value} />
      <NoDataView dragging sourceAvailable />
      <ImportOverlay dragging sourceAvailable onDragLeave handleDrop />
    </Content>
    <Sidebar sourceAvailable>
      <Sidebar.Button onClick=onCreateTarget> {"Add language"->s} </Sidebar.Button>
      <Sidebar.Button onClick=onExportCsv> {"Export CSV"->s} </Sidebar.Button>
      <Sidebar.Button onClick=onExportAll> {"Export all JSON"->s} </Sidebar.Button>
    </Sidebar>
  </div>
}
