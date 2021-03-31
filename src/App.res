open Stdlib
open ReactUtils

%%private(
  let swapIndex = (data, index) =>
    data->Array.map(row => {
      if index !== 1 {
        row->Array.swap(index, 1)
      } else {
        row
      }
    })
)

%%private(
  let cellRenderer = (
    {cell, className, children, onDoubleClick, onMouseDown, onMouseOver}: DataSheet.CellProps.t,
  ) =>
    <td
      onMouseDown={onMouseDown}
      onMouseOver={onMouseOver}
      onDoubleClick={onDoubleClick}
      className={className->Cn.addIf(
        cell.value->String.length === 0 ||
          (cell.value === ReactUtils.nbsp &&
          !(className->String.includes("description")) &&
          !(className->String.includes("read-only"))),
        "blank",
      )}>
      {children}
    </td>
)

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

  let handleDrop = (e, sourceOrTarget: FileUtils.file) => {
    e->cancelMouseEvent
    let files = e->File.fromMouseEvent

    if files->Array.length === 1 {
      let file = files[0]
      let fileType = file->Option.flatMap(File.getFileType)

      switch (file, fileType) {
      | (Some(file), Some(Json)) =>
        File.read(file, result =>
          dispatch(
            SetData(
              result
              ->File.resultToJson
              ->Option.mapWithDefault(data, result =>
                switch sourceOrTarget {
                | Source =>
                  dispatch(SetMode(Json))

                  result->Message.fromJson->Source.make(file.name)
                | Target => result->Message.fromJson->Source.add(data, file.name)
                }
              ),
            ),
          )
        )

      | (Some(file), Some(Csv)) =>
        File.read(file, result => {
          switch result->File.FileResult.toString->Papa.parse {
          | Success(parseResult, delimiter) =>
            let commentIndex =
              parseResult
              ->Array.getUnsafe(0)
              ->Array.getIndexBy(text =>
                ["comments", "comment", "description"]->Array.some(str =>
                  text->String.toLowerCase->String.includes(str)
                )
              )

            dispatch(SetMode(Csv({commentIndex: commentIndex, delimiter: delimiter})))

            let source = switch commentIndex {
            | Some(commentIndex) => parseResult->swapIndex(commentIndex)
            | None => parseResult
            }

            dispatch(SetData(source->Source.fromCsv))

          | Error => ()
          }
        })

      | (Some(file), Some(Xml)) =>
        file->File.read(result => {
          let source = result->File.FileResult.toString->Convert.Xml.toArray

          dispatch(
            SetData(
              switch sourceOrTarget {
              | Source => source->Source.make(file.name)
              | Target => source->Source.add(data, file.name)
              },
            ),
          )
        })

      | (Some(file), Some(Strings)) =>
        file->File.read(result => {
          let source = result->File.FileResult.toString->Convert.Strings.toArray

          dispatch(
            SetData(
              switch sourceOrTarget {
              | Source => source->Source.make(file.name)
              | Target => source->Source.add(data, file.name)
              },
            ),
          )
        })

      | (Some(file), Some(Properties)) =>
        file->File.read(~encoding=#"ISO-8859-1", result => {
          let source = result->File.FileResult.toString->Convert.Properties.toArray

          dispatch(
            SetData(
              switch sourceOrTarget {
              | Source => source->Source.make(file.name)
              | Target => source->Source.add(data, file.name)
              },
            ),
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
        dispatch(SetData(results->Array.keepMap(a => a)->Source.addMultiple(data)))
      )
    }

    setDragging(_ => false)
  }

  let onCellsChanged = React.useCallback1(changes => {
    let dataSheet = data->Array.copy

    changes->Array.forEach(change => dataSheet->Source.update(change))

    dispatch(SetData(dataSheet))
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
    data[0]
    ->Option.getWithDefault([])
    ->Array.forEachWithIndex((i, cell) =>
      if i > 0 {
        data
        ->Convert.Json.fromData(cell.value)
        ->FileUtils.download(~download={cell.value ++ ".json"})
      }
    )
  }, [data])

  let onExportCsv = React.useCallback2(_evt => {
    let (newData, delimiter) = switch state.mode {
    | Csv({commentIndex: Some(index), delimiter}) => (data->swapIndex(index), delimiter)
    | Csv({delimiter}) => (data, delimiter)
    | _ => (data, ";")
    }

    newData
    ->Convert.CSV.fromData(~delimiter)
    ->FileUtils.download(~download={FileUtils.timestampFilename("export.csv")})
  }, (state.mode, data))

  let sheetRenderer = (props: DataSheet.SheetProps.t) =>
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
              dispatch
            />
          )
          ->React.array}
        </tr>
      </thead>
      <tbody> {props.children} </tbody>
    </table>

  <div className="App" onDragOver>
    <Content sourceAvailable>
      <DataSheet
        data onCellsChanged sheetRenderer cellRenderer valueRenderer={cell => cell.value}
      />
      <NoDataView dragging sourceAvailable />
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
