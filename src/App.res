open Belt
open ReactUtils

module HeaderCol = {
  @react.component
  let make = (~index, ~value, ~onExport, ~onRemoveTarget, ~onRemoveSource) => {
    <th>
      <div className="ButtonRow">
        {if index === 0 {
          <IconButton onClick=onRemoveSource title={"Remove source"} icon=#trash />
        } else if index > 1 {
          <>
            <div className="ExportButtonRow">
              <IconButton
                title={"Export JSON file"}
                onClick={evt => onExport(value, File.FileType.Json)}
                icon=#json
              />
              <IconButton
                title={"Export Properties file"}
                onClick={evt => onExport(value, Properties)}
                icon=#properties
              />
              <IconButton
                title={"Export Strings file"}
                onClick={evt => onExport(value, Strings)}
                icon=#strings
              />
              <IconButton
                title={"Export Android XML resources file"}
                onClick={evt => onExport(value, Xml)}
                icon=#xml
              />
            </div>
            {if index > 2 {
              <div className="ActionButtonRow">
                <IconButton
                  title={"Remove column"} onClick={evt => onRemoveTarget(value)} icon=#trash
                />
              </div>
            } else {
              React.null
            }}
          </>
        } else {
          React.null
        }}
      </div>
    </th>
  }
}

@react.component
let make = () => {
  let (data, setData) = React.useState(() => Source.empty())
  let (dragging, setDragging, onDragOver, onDragLeave) = Hooks.useDrag()

  let sourceAvailable = data->Array.length > 0

  let handleDrop = (e, sourceOrTarget: FileUtils.file) => {
    e->cancelMouseEvent
    let files = e->File.fromMouseEvent

    if files->Array.length === 1 {
      let file = files[0]
      let fileType = file->Option.flatMap(File.getFileType)

      switch (file, fileType) {
      | (Some(file), Some(Json)) =>
        File.read(file, result =>
          setData(_ =>
            result
            ->File.resultToJson
            ->Option.mapWithDefault(data, result =>
              switch sourceOrTarget {
              | Source => result->Message.fromJson->Source.make(file.name)
              | Target => result->Message.fromJson->Source.add(data, file.name)
              }
            )
          )
        )

      | (Some(file), Some(Csv)) =>
        File.read(file, result => {
          let source = result->File.FileResult.toString->Convert.CSV.toArray

          setData(_ => source->Source.fromCsv)
        })

      | (Some(file), Some(Xml)) =>
        file->File.read(result => {
          let source = result->File.FileResult.toString->Convert.Xml.toArray

          setData(_ =>
            switch sourceOrTarget {
            | Source => source->Source.make(file.name)
            | Target => source->Source.add(data, file.name)
            }
          )
        })

      | (Some(file), Some(Strings)) =>
        file->File.read(result => {
          let source = result->File.FileResult.toString->Convert.Strings.toArray

          setData(_ =>
            switch sourceOrTarget {
            | Source => source->Source.make(file.name)
            | Target => source->Source.add(data, file.name)
            }
          )
        })

      | (Some(file), Some(Properties)) =>
        file->File.read(~encoding=#"ISO-8859-1", result => {
          let source = result->File.FileResult.toString->Convert.Properties.toArray

          setData(_ =>
            switch sourceOrTarget {
            | Source => source->Source.make(file.name)
            | Target => source->Source.add(data, file.name)
            }
          )
        })

      | _ => ()
      }
    } else {
      files
      ->Array.map(file =>
        Promise.exec(resolve =>
          if sourceOrTarget === Target && file->File.isJson {
            File.read(file, resolve)
          }
        )->Promise.map(res =>
          res->File.resultToJson->Option.flatMap(result => Some(file.name, result))
        )
      )
      ->Promise.allArray
      ->Promise.get(results =>
        setData(_ => results->Array.keepMap(a => a)->Source.addMultiple(data))
      )
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

  let onExport = (col, fileType) => {
    let download = col ++ fileType->File.FileType.toExtension

    switch fileType {
    | Json => data->Convert.Json.fromData(col)->FileUtils.download(~download)
    | Properties => data->Convert.Properties.fromData(col)->FileUtils.download(~download)
    | Strings => data->Convert.Strings.fromData(col)->FileUtils.download(~download)
    | Xml => data->Convert.Xml.fromData(col)->FileUtils.download(~download)
    | _ => ()
    }
  }

  let onExportAll = _evt => {
    data[0]
    ->Option.getWithDefault([])
    ->Array.forEachWithIndex((i, cell) =>
      if i > 0 {
        data
        ->Convert.Json.fromData(cell.value)
        ->FileUtils.download(~download={cell.value ++ ".json"})
      }
    )
  }

  let onExportCsv = _evt =>
    data
    ->Convert.CSV.fromData
    ->FileUtils.download(~download={FileUtils.timestampFilename("export.csv")})

  let sheetRenderer = (props: DataSheet.SheetProps.t) => {
    <table className={props.className}>
      <thead>
        {sourceAvailable
          ? <tr> <th> {"Source"->s} </th> <th /> <th /> <th> {"Targets"->s} </th> </tr>
          : React.null}
        <tr>
          {data[0]
          ->Option.getWithDefault([])
          ->Array.mapWithIndex((i, {value}) =>
            <HeaderCol key={i->Int.toString} index=i value onExport onRemoveTarget onRemoveSource />
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
      <IconButton title={"Add new language"} size=#Large onClick={onCreateTarget} icon=#plus />
      <IconButton title={"Export to CSV"} size=#Large onClick={onExportCsv} icon=#csv />
      <IconButton title={"Export all JSON files"} size=#Large onClick={onExportAll} icon=#json />
    </Sidebar>
  </div>
}
