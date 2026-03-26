module Cell = {
  @@live

  type t = {
    value: string,
    expr: option<string>,
    readOnly: bool,
    width: option<int>,
    className: string,
  }

  let make = (~expr=None, ~readOnly=false, ~className="", value) => {
    value,
    expr,
    readOnly,
    width: None,
    className,
  }

  let makeRO = value => {...make(value), readOnly: true}

  let empty = () => {
    value: "",
    expr: None,
    readOnly: false,
    width: Some(100),
    className: "",
  }

  let emptyRO = () => {...empty(), readOnly: true}
}

type data = array<array<Cell.t>>

module Change = {
  type t = {@live cell: Cell.t, col: int, row: int, value: string}
}

let update = (grid, {Change.row: _row as rowIndex, col, value}) => {
  let row = grid->Array.getUnsafe(rowIndex)
  let cell = row->Array.getUnsafe(col)

  let newCell = {...cell, Cell.value}
  row->Array.setUnsafe(col, newCell)

  grid->Array.setUnsafe(rowIndex, row)
}

let inputId = (row, col) => `data-grid-input-${row->Int.toString}-${col->Int.toString}`
let cellId = (row, col) => `data-grid-cell-${row->Int.toString}-${col->Int.toString}`

let focusCell = (~row, ~col, ~selectInput) =>
  Document.document
  ->Document.getElementById(selectInput ? inputId(row, col) : cellId(row, col))
  ->Option.forEach(element => {
    element->HtmlElement.focus
    if selectInput {
      element->HtmlElement.select
    }
  })

let parseClipboard = text =>
  text
  ->String.replace("\r\n", "\n")
  ->String.replace("\r", "\n")
  ->String.split("\n")
  ->Array.filter(line => line != "")
  ->Array.map(line => line->String.split("\t"))

let cellClassName = (cell: Cell.t) =>
  "cell"
  ->Cn.addIf(cell.readOnly, "read-only")
  ->Cn.addIf(cell.className != "", cell.className)
  ->Cn.addIf(!cell.readOnly && (cell.value === "" || cell.value === ReactUtils.nbsp), "blank")

let makeChange = (~cell: Cell.t, ~row, ~col, ~value): Change.t => {cell, row, col, value}

module Editor = {
  let resizeToFit = element => {
    let style = element->HtmlElement.style
    style->HtmlElement.setProperty("height", "0px")
    style->HtmlElement.setProperty("height", `${element->HtmlElement.scrollHeight->Int.toString}px`)
  }

  @react.component
  let make = (~cell: Cell.t, ~rowIndex, ~colIndex, ~onChange, ~onKeyDown, ~onPaste) => {
    let ref: ReactDOM.Ref.currentDomRef = React.useRef(null)
    let cellValue = cell.value

    React.useLayoutEffect(() => {
      ref.current->Nullable.forEach(resizeToFit)
      None
    }, [cellValue])

    <textarea
      ref={ref->ReactDOM.Ref.domRef}
      id={inputId(rowIndex, colIndex)}
      className="data-editor"
      rows=1
      value={cellValue}
      onChange
      onKeyDown
      onPaste
    />
  }
}

@react.component
let make = (~data, ~valueRenderer, ~onCellsChanged, ~hiddenCols: array<int>=[]) => {
  let isHiddenCol = colIndex => hiddenCols->Array.includes(colIndex)
  let isUntranslatedCell = (cell: Cell.t) =>
    !cell.readOnly && cell.value->String.trim->String.length === 0

  let focusGridPosition = (rowIndex, colIndex) =>
    if !isHiddenCol(colIndex) {
      switch data[rowIndex] {
      | Some(row) =>
        switch row[colIndex] {
        | Some(cell: Cell.t) => focusCell(~row=rowIndex, ~col=colIndex, ~selectInput=!cell.readOnly)
        | None => ()
        }
      | None => ()
      }
    }

  let jumpToUntranslated = (rowIndex, colIndex, step) => {
    let rec loop = nextRowIndex =>
      switch data[nextRowIndex] {
      | Some(row) =>
        switch row[colIndex] {
        | Some(cell: Cell.t) =>
          if cell->isUntranslatedCell {
            focusGridPosition(nextRowIndex, colIndex)
          } else {
            loop(nextRowIndex + step)
          }
        | None => ()
        }
      | None => ()
      }

    loop(rowIndex + step)
  }

  let moveVertical = (rowIndex, colIndex, step) => {
    let loop = nextRowIndex =>
      switch data[nextRowIndex] {
      | Some(_) => focusGridPosition(nextRowIndex, colIndex)
      | None => ()
      }

    loop(rowIndex + step)
  }

  let moveHorizontal = (rowIndex, colIndex, step) => {
    let rec loop = nextColIndex =>
      switch data[rowIndex] {
      | Some(row) =>
        switch row[nextColIndex] {
        | Some(_) =>
          if isHiddenCol(nextColIndex) {
            loop(nextColIndex + step)
          } else {
            focusGridPosition(rowIndex, nextColIndex)
          }
        | None => ()
        }
      | None => ()
      }

    loop(colIndex + step)
  }

  let moveTab = (rowIndex, colIndex, backwards) => {
    let step = backwards ? -1 : 1

    let rec loop = (nextRowIndex, nextColIndex) =>
      switch data[nextRowIndex] {
      | Some(row) =>
        switch row[nextColIndex] {
        | Some(_) =>
          if isHiddenCol(nextColIndex) {
            loop(nextRowIndex, nextColIndex + step)
          } else {
            focusGridPosition(nextRowIndex, nextColIndex)
          }
        | None =>
          if backwards {
            switch data[nextRowIndex - 1] {
            | Some(previousRow) => loop(nextRowIndex - 1, previousRow->Array.length - 1)
            | None => ()
            }
          } else {
            loop(nextRowIndex + 1, 0)
          }
        }
      | None => ()
      }

    loop(rowIndex, colIndex + step)
  }

  let onInputKeyDown = (rowIndex, colIndex) =>
    evt => {
      evt->ReactEvent.Keyboard.preventDefault

      switch evt->ReactEvent.Keyboard.key {
      | "ArrowUp" if evt->ReactEvent.Keyboard.altKey => jumpToUntranslated(rowIndex, colIndex, -1)
      | "ArrowDown" if evt->ReactEvent.Keyboard.altKey => jumpToUntranslated(rowIndex, colIndex, 1)
      | "ArrowUp" => moveVertical(rowIndex, colIndex, -1)
      | "ArrowDown" => moveVertical(rowIndex, colIndex, 1)
      | "ArrowLeft" => moveHorizontal(rowIndex, colIndex, -1)
      | "ArrowRight" => moveHorizontal(rowIndex, colIndex, 1)
      | "Enter" => jumpToUntranslated(rowIndex, colIndex, 1)
      | "Tab" => moveTab(rowIndex, colIndex, evt->ReactEvent.Keyboard.shiftKey)
      | _ => ()
      }
    }

  let onReadOnlyKeyDown = (rowIndex, colIndex) =>
    evt => {
      evt->ReactEvent.Keyboard.preventDefault

      switch evt->ReactEvent.Keyboard.key {
      | "ArrowUp" if evt->ReactEvent.Keyboard.altKey => jumpToUntranslated(rowIndex, colIndex, -1)
      | "ArrowDown" if evt->ReactEvent.Keyboard.altKey => jumpToUntranslated(rowIndex, colIndex, 1)
      | "ArrowUp" => moveVertical(rowIndex, colIndex, -1)
      | "ArrowDown" => moveVertical(rowIndex, colIndex, 1)
      | "ArrowLeft" => moveHorizontal(rowIndex, colIndex, -1)
      | "ArrowRight" => moveHorizontal(rowIndex, colIndex, 1)
      | "Enter" => jumpToUntranslated(rowIndex, colIndex, 1)
      | "Tab" => moveTab(rowIndex, colIndex, evt->ReactEvent.Keyboard.shiftKey)
      | _ => ()
      }
    }

  let onInputChange = (rowIndex, colIndex, cell) =>
    evt =>
      onCellsChanged([
        makeChange(~cell, ~row=rowIndex, ~col=colIndex, ~value=ReactUtils.valueFromEvent(evt)),
      ])

  let onInputPaste = (rowIndex, colIndex) =>
    evt => {
      let changes = switch evt->Clipboard.getText {
      | Some(text) =>
        let changes = []
        let rows = text->parseClipboard

        rows->Array.forEachWithIndex((rowValues, rowOffset) =>
          rowValues->Array.forEachWithIndex((value, colOffset) => {
            let targetRowIndex = rowIndex + rowOffset
            let targetColIndex = colIndex + colOffset

            switch data[targetRowIndex] {
            | Some(targetRow) =>
              switch targetRow[targetColIndex] {
              | Some(cell: Cell.t) if !cell.readOnly =>
                changes->Array.push(
                  Some(makeChange(~cell, ~row=targetRowIndex, ~col=targetColIndex, ~value)),
                )
              | _ => ()
              }
            | None => ()
            }
          })
        )

        changes->Array.filterMap(change => change)
      | None => []
      }

      if changes->Array.length > 0 {
        evt->ReactEvent.Clipboard.preventDefault
        onCellsChanged(changes)
      }
    }

  <>
    {data
    ->Array.slice(~start=1, ~end=data->Array.length)
    ->Array.mapWithIndex((row, bodyRowIndex) => {
      let rowIndex = bodyRowIndex + 1

      <tr key={rowIndex->Int.toString}>
        {row
        ->Array.mapWithIndex((cell, colIndex) => {
          let renderedValue = valueRenderer(cell)
          let value = renderedValue === ReactUtils.nbsp ? "" : renderedValue

          <td
            key={`${rowIndex->Int.toString}-${colIndex->Int.toString}`}
            id={cellId(rowIndex, colIndex)}
            className={cell->cellClassName}
            tabIndex={cell.readOnly ? 0 : -1}
            onKeyDown={cell.readOnly ? onReadOnlyKeyDown(rowIndex, colIndex) : _evt => ()}
          >
            {cell.readOnly
              ? <div className="text"> {value->ReactUtils.s} </div>
              : <Editor
                  cell
                  rowIndex
                  colIndex
                  onChange={onInputChange(rowIndex, colIndex, cell)}
                  onKeyDown={onInputKeyDown(rowIndex, colIndex)}
                  onPaste={onInputPaste(rowIndex, colIndex)}
                />}
          </td>
        })
        ->React.array}
      </tr>
    })
    ->React.array}
  </>
}
