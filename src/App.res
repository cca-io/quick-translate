open Belt
open ReactUtils

type mode = Json | Other

@react.component
let make = () => {
  let (data, setData) = React.useState(() => Source.empty())
  let (dragging, setDragging, onDragOver, onDragLeave) = Hooks.useDrag()
  let (useDescription, setUseDescription) = React.useState(() => false)
  let (mode, setMode) = React.useState(() => Other)

  let canToggleDescription = mode === Json
  let showDescriptionCol = useDescription && canToggleDescription

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
              | Source =>
                setMode(_ => Json)
                result->Message.fromJson->Source.make(file.name)
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

  let onToggleDescriptions = _evt => setUseDescription(value => !value)

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
      setMode(_ => Other)
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
    <table className={props.className->Cn.addIf(!showDescriptionCol, "withoutDescription")}>
      <thead>
        {sourceAvailable
          ? <tr> <th> {"Source"->s} </th> <th /> <th /> <th> {"Targets"->s} </th> </tr>
          : React.null}
        <tr>
          {data[0]
          ->Option.getWithDefault([])
          ->Array.mapWithIndex((i, {value}) =>
            <HeaderCol
              key={i->Int.toString}
              index={i}
              useDescription
              canToggleDescription
              value
              onExport
              onRemoveTarget
              onRemoveSource
              onToggleDescriptions
            />
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
