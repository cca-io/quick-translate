open Stdlib
open ReactUtils

@react.component
let make = () => {
  let (state, dispatch) = React.useReducer(AppState.reducer, AppState.initialState)
  let (dragging, setDragging, onDragOver, onDragLeave) = Hooks.useDrag()
  let {data, useDescription} = state

  let canToggleDescription = state.mode !== Other
  let showDescriptionCol = state.useDescription && canToggleDescription
  let sourceAvailable = data->Array.length > 0

  let onCreateTarget = _evt => dispatch(SetDialog(CreateTarget))
  let onOpenHelp = _evt => dispatch(SetDialog(Help))

  Hooks.useMultiKeyPress(["Control", "Shift", "?"], () => dispatch(SetDialog(Help)))
  Hooks.useMultiKeyPress(["Control", "Shift", "N"], () => dispatch(SetDialog(CreateTarget)))
  Hooks.useMultiKeyPress(["Control", "Shift", "R"], () => dispatch(SetDialog(RemoveSource)))
  Hooks.useMultiKeyPress(["Control", "Shift", "D"], () => dispatch(ToggleUseDescription))

  Hooks.useMultiKeyPress(["Control", "z"], () => dispatch(Undo))
  Hooks.useMultiKeyPress(["Control", "Shift", "Z"], () => dispatch(Redo))

  let handleFiles = (files, sourceOrTarget: FileUtils.file) => {
    if files->Array.length === 1 {
      let file = files[0]
      let fileType = file->Option.flatMap(File.getFileType)

      switch (file, fileType) {
      | (Some(file), Some(Json)) =>
        let readFile = async () => {
          let result = await File.read(file)

          let data =
            result
            ->File.resultToJson
            ->Option.mapWithDefault(data, result =>
              switch sourceOrTarget {
              | Source =>
                dispatch(SetMode(Json))

                result->Message.fromJson->Source.make(file.name)
              | Target => data->Source.add(result->Message.fromJson, file.name)
              }
            )

          dispatch(SetData(data))
        }

        let _ = readFile()

      | (Some(file), Some(Csv)) =>
        let readFile = async () => {
          let result = await File.read(file)

          switch result->File.FileResult.toString->Papa.parse {
          | Success(parseResult, delimiter) =>
            let commentIndex =
              parseResult
              ->Array.getUnsafe(0)
              ->Array.getIndexBy(text => text->SourceUtils.isCommentColumn)

            dispatch(SetMode(Csv({commentIndex, delimiter})))

            let source = switch commentIndex {
            | Some(commentIndex) => parseResult->SourceUtils.swapIndex(commentIndex)
            | None => parseResult
            }

            dispatch(SetData(source->Source.fromCsv))

          | Error => ()
          }
        }

        let _ = readFile()

      | (Some(file), Some(Xml)) =>
        let readFile = async () => {
          let result = await File.read(file)
          let source = result->File.FileResult.toString->Convert.Xml.toArray

          dispatch(
            SetData(
              switch sourceOrTarget {
              | Source => source->Source.make(file.name)
              | Target => data->Source.add(source, file.name)
              },
            ),
          )
        }

        let _ = readFile()

      | (Some(file), Some(Strings)) =>
        let readFile = async () => {
          let result = await File.read(file)
          let source = result->File.FileResult.toString->Convert.Strings.toArray

          dispatch(
            SetData(
              switch sourceOrTarget {
              | Source => source->Source.make(file.name)
              | Target => data->Source.add(source, file.name)
              },
            ),
          )
        }

        let _ = readFile()

      | (Some(file), Some(Properties)) =>
        let readFile = async () => {
          let result = await File.read(file, ~encoding=#"ISO-8859-1")
          let source = result->File.FileResult.toString->Convert.Properties.toArray

          dispatch(
            SetData(
              switch sourceOrTarget {
              | Source => source->Source.make(file.name)
              | Target => data->Source.add(source, file.name)
              },
            ),
          )
        }

        let _ = readFile()

      | _ => ()
      }
    } else {
      let readFiles = async () => {
        let results = []

        for i in 0 to files->Array.length - 1 {
          switch files[i] {
          | None => ()
          | Some(file) =>
            if sourceOrTarget === Target && file->File.isJson {
              let result = await File.read(file)
              let _ =
                results->Js.Array2.push(
                  result->File.resultToJson->Option.flatMap(result => Some(file.name, result)),
                )
            }
          }
        }

        dispatch(SetData(data->Source.addMultiple(results->Array.keepMap(a => a))))
      }

      let _ = readFiles()
    }

    setDragging(_ => false)
  }

  let handleDrop = (e, sourceOrTarget: FileUtils.file) => {
    e->cancelMouseEvent
    let files = e->File.fromMouseEvent

    handleFiles(files, sourceOrTarget)
  }

  let handleUploadClicked = (e, sourceOrTarget: FileUtils.file) => {
    let files = e->File.fromFormEvent

    handleFiles(files, sourceOrTarget)
  }

  let onCellsChanged = React.useCallback1(changes => {
    let changedData = data->Source.update(changes)

    dispatch(SetData(changedData))
  }, [data])

  let onExport = React.useCallback1((col, fileType) => {
    let download = col ++ fileType->File.FileType.toExtension

    switch fileType {
    | Json => data->Convert.Json.fromData(col)->FileUtils.download(~download)
    | Properties => data->Convert.Properties.fromData(col)->FileUtils.download(~download)
    | Strings => data->Convert.Strings.fromData(col)->FileUtils.download(~download)
    | Xml => data->Convert.Xml.fromData(col)->FileUtils.download(~download)
    | _ => ()
    }
  }, [data])

  let onExportAll = React.useCallback1(_evt => {
    let zip = JsZip.make()

    data[0]
    ->Option.getWithDefault([])
    ->Array.forEachWithIndex((i, cell) =>
      if i > 0 {
        zip->JsZip.file(cell.value ++ ".json", data->Convert.Json.fromDataAsBlob(cell.value))
      }
    )

    let performDownload = async () => {
      let blob = await (zip->JsZip.generateAsync({\"type": #blob}))
      blob->Blob.toUrl->FileUtils.download(~download="all.zip")
    }

    let _ = performDownload()
  }, [data])

  let onExportCsv = React.useCallback2(_evt => {
    let (newData, delimiter) = switch state.mode {
    | Csv({commentIndex: Some(index), delimiter}) => (data->SourceUtils.swapIndex(index), delimiter)
    | Csv({delimiter}) => (data, delimiter)
    | _ => (data, ";")
    }

    newData
    ->Convert.CSV.fromData(~delimiter)
    ->FileUtils.download(~download=FileUtils.timestampFilename("export.csv"))
  }, (state.mode, data))

  let sheetRenderer = ({data, className, children}: DataSheet.SheetProps.t) =>
    <table className={className->Cn.addIf(!showDescriptionCol, "withoutDescription")}>
      <thead>
        {sourceAvailable
          ? <tr>
              <th> {"Source"->s} </th>
              <th />
              <th />
              <th> {"Targets"->s} </th>
              {data[0]
              ->Option.getWithDefault([])
              ->Array.mapWithIndex((i, _) => i > 3 ? <th key={i->Int.toString} /> : React.null)
              ->React.array}
            </tr>
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
              dispatch
            />
          )
          ->React.array}
        </tr>
      </thead>
      <tbody> {children} </tbody>
    </table>

  let cellRenderer = (
    {cell, className, children, onDoubleClick, onMouseDown, onMouseOver}: DataSheet.CellProps.t,
  ) => {
    let className =
      className->Cn.addIf(
        cell.value->String.length === 0 ||
          (cell.value === nbsp &&
          !(className->String.includes("description")) &&
          !(className->String.includes("read-only"))),
        "blank",
      )

    <td onMouseDown onMouseOver onDoubleClick className> {children} </td>
  }

  <div className="App" onDragOver>
    <Content sourceAvailable>
      <DataSheet
        data onCellsChanged sheetRenderer cellRenderer valueRenderer={cell => cell.value}
      />
      <NoDataView dragging sourceAvailable handleUploadClicked />
      <ImportOverlay dragging sourceAvailable onDragLeave handleDrop />
    </Content>
    <Sidebar sourceAvailable>
      <Sidebar.Top>
        <IconButton title={"Add new language"} size=#Large onClick={onCreateTarget} icon=#plus />
        <IconButton title={"Export to CSV"} size=#Large onClick={onExportCsv} icon=#csv />
        <IconButton title={"Export all JSON files"} size=#Large onClick={onExportAll} icon=#json />
      </Sidebar.Top>
      <Sidebar.Bottom>
        <IconButton title={"Help"} onClick={onOpenHelp} icon=#help />
      </Sidebar.Bottom>
    </Sidebar>
    <Dialogs dialog=state.dialog data dispatch />
  </div>
}
