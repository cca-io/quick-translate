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
let editCommitDelayMs = 1500

let stickyHeaderBottom = (~containerTop, element) => {
  open WebAPI

  let table: Null.t<DOMAPI.element> = element->Element.closest(".data-grid")

  table
  ->Null.toOption
  ->Option.mapOr(containerTop, table => {
    let headers = table->Element.querySelectorAll("thead th")
    let bottom = ref(containerTop)

    for index in 0 to headers.length - 1 {
      let headerRect = headers->NodeList.item(index)->Element.getBoundingClientRect

      if headerRect.bottom > bottom.contents {
        bottom.contents = headerRect.bottom
      }
    }

    bottom.contents
  })
}

let correctStickyHeaderScroll = element => {
  open WebAPI

  let scrollContainer: Null.t<DOMAPI.htmlElement> = element->Element.closest(".with-margin")

  scrollContainer->Null.forEach(container => {
    let elementRect = element->Element.getBoundingClientRect
    let containerRect = container->HTMLElement.asElement->Element.getBoundingClientRect
    let visibleTop = element->stickyHeaderBottom(~containerTop=containerRect.top)
    let visibleBottom = containerRect.bottom

    if elementRect.top < visibleTop {
      container.scrollTop = container.scrollTop -. (visibleTop -. elementRect.top)
    } else if elementRect.bottom > visibleBottom {
      container.scrollTop = container.scrollTop +. (elementRect.bottom -. visibleBottom)
    }
  })
}

let focusGridCell = (
  ~row,
  ~col,
  ~block=WebAPI.DOMAPI.Nearest,
  ~inlinePosition=WebAPI.DOMAPI.Nearest,
  ~correctForStickyHeader=true,
) => {
  open WebAPI

  document
  ->Document.getElementById(cellId(row, col))
  ->Null.forEach(element => {
    element->Element.scrollIntoViewWithOptions({block, inline: inlinePosition})
    if correctForStickyHeader {
      element->correctStickyHeaderScroll
    }
    element->HtmlCast.fromWebElement->HTMLElement.focus(~options={preventScroll: true})
  })
}

let focusEditor = (
  ~row,
  ~col,
  ~select=false,
  ~cursorAtEnd=false,
  ~block=WebAPI.DOMAPI.Nearest,
  ~inlinePosition=WebAPI.DOMAPI.Nearest,
  ~correctForStickyHeader=true,
) => {
  open WebAPI

  document
  ->Document.getElementById(inputId(row, col))
  ->Null.forEach(element => {
    element->Element.scrollIntoViewWithOptions({block, inline: inlinePosition})
    if correctForStickyHeader {
      element->correctStickyHeaderScroll
    }
    let element = element->HtmlCast.textAreaFromWebElement
    element->HTMLTextAreaElement.focus(~options={preventScroll: true})
    if select {
      element->HTMLTextAreaElement.select
    } else if cursorAtEnd {
      element->HTMLTextAreaElement.setSelectionRange(
        ~start=element.value->String.length,
        ~end=element.value->String.length,
      )
    }
  })
}

let focusEditorLater = (
  ~row,
  ~col,
  ~select=false,
  ~cursorAtEnd=false,
  ~block=WebAPI.DOMAPI.Nearest,
  ~inlinePosition=WebAPI.DOMAPI.Nearest,
  ~correctForStickyHeader=true,
) =>
  WebAPI.Global.setTimeout(
    ~handler=() =>
      focusEditor(
        ~row,
        ~col,
        ~select,
        ~cursorAtEnd,
        ~block,
        ~inlinePosition,
        ~correctForStickyHeader,
      ),
    ~timeout=0,
  )->ignore

let activeElementId = () =>
  WebAPI.Global.document.activeElement
  ->Null.toOption
  ->Option.map(element => element.id)
  ->Option.getOr("")

let normalizeClipboardNewlines = text => text->String.replaceRegExp(/\r\n?/g, "\n")

let containsClipboardNewline = text => text->String.includes("\n") || text->String.includes("\r")

let containsClipboardTab = text => text->String.includes("\t")

let shouldPasteAcrossGrid = text => !(text->containsClipboardNewline) && text->containsClipboardTab

let parseClipboard = text =>
  text
  ->normalizeClipboardNewlines
  ->String.split("\n")
  ->Array.filter(line => line != "")
  ->Array.map(line => line->String.split("\t"))

let cellClassName = (cell: Cell.t) =>
  "cell"
  ->Cn.addIf(cell.readOnly, "read-only")
  ->Cn.addIf(cell.className != "", cell.className)
  ->Cn.addIf(!cell.readOnly && (cell.value === "" || cell.value === ReactUtils.nbsp), "blank")

let makeChange = (~cell: Cell.t, ~row, ~col, ~value): Change.t => {cell, row, col, value}

type cellMeta = {
  className: string,
  title: option<string>,
}

module Editor = {
  let resizeToFit = element => {
    open WebAPI

    let element = element->HtmlCast.textAreaFromLegacyDomElement
    element.style->CSSStyleDeclaration.setProperty(~property="height", ~value="0px")
    element.style->CSSStyleDeclaration.setProperty(
      ~property="height",
      ~value=`${element.scrollHeight->Int.toString}px`,
    )
  }

  @react.component
  let make = (~cell: Cell.t, ~rowIndex, ~colIndex, ~onChange, ~onKeyDown, ~onPaste, ~onBlur) => {
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
      tabIndex={-1}
      value={cellValue}
      onChange
      onKeyDown
      onPaste
      onBlur
    />
  }
}

@react.component
let make = (
  ~data,
  ~valueRenderer,
  ~onCellsChanged,
  ~onCellsCommitted,
  ~getCellMeta=(_, _, _) => None,
  ~hiddenCols: array<int>=[],
) => {
  let commitTimerRef: React.ref<option<WebAPI.DOMAPI.timeoutId>> = React.useRef(None)
  let clearScheduledCommit = () => {
    switch commitTimerRef.current {
    | Some(timeoutId) =>
      WebAPI.Global.clearTimeout(timeoutId)
      commitTimerRef.current = None
    | None => ()
    }
  }
  let commitNow = () => {
    clearScheduledCommit()
    onCellsCommitted()
  }
  let scheduleCommit = () => {
    clearScheduledCommit()
    commitTimerRef.current = Some(
      WebAPI.Global.setTimeout(~handler=onCellsCommitted, ~timeout=editCommitDelayMs),
    )
  }

  React.useEffect(() => Some(() => clearScheduledCommit()), [])

  let isHiddenCol = colIndex => hiddenCols->Array.includes(colIndex)
  let isUntranslatedCell = (cell: Cell.t) =>
    !cell.readOnly && cell.value->String.trim->String.length === 0
  let isInvalidCell = (rowIndex, colIndex, cell: Cell.t) =>
    !cell.readOnly &&
      switch getCellMeta(rowIndex, colIndex, cell) {
      | Some(meta) => meta.className->String.includes("intl-invalid")
      | None => cell.className->String.includes("intl-invalid")
      }
  let isIssueCell = (rowIndex, colIndex, cell) =>
    isUntranslatedCell(cell) || isInvalidCell(rowIndex, colIndex, cell)
  let isEditorFocused = (rowIndex, colIndex) => activeElementId() === inputId(rowIndex, colIndex)

  let focusGridPosition = (
    ~block=WebAPI.DOMAPI.Nearest,
    ~inlinePosition=WebAPI.DOMAPI.Nearest,
    ~correctForStickyHeader=true,
    rowIndex,
    colIndex,
  ) =>
    if !isHiddenCol(colIndex) {
      switch data[rowIndex] {
      | Some(row) =>
        switch row[colIndex] {
        | Some(_) =>
          focusGridCell(
            ~row=rowIndex,
            ~col=colIndex,
            ~block,
            ~inlinePosition,
            ~correctForStickyHeader,
          )
        | None => ()
        }
      | None => ()
      }
    }

  let jumpToIssue = (rowIndex, colIndex, step) => {
    let bodyLength = data->Array.length - 1

    if bodyLength > 0 {
      let currentBodyIndex =
        if rowIndex >= 1 && rowIndex < data->Array.length {
          rowIndex - 1
        } else if step < 0 {
          0
        } else {
          -1
        }
      let normalizeBodyIndex = index => ((index % bodyLength) + bodyLength) % bodyLength

      let rec loop = offset =>
        if offset <= bodyLength {
          let signedOffset = step > 0 ? offset : -offset
          let nextBodyIndex = normalizeBodyIndex(currentBodyIndex + signedOffset)
          let nextRowIndex = nextBodyIndex + 1

          switch data[nextRowIndex] {
          | Some(row) =>
            switch row[colIndex] {
            | Some(cell: Cell.t) if isIssueCell(nextRowIndex, colIndex, cell) =>
              focusGridPosition(
                ~block=WebAPI.DOMAPI.Center,
                ~inlinePosition=WebAPI.DOMAPI.Center,
                ~correctForStickyHeader=false,
                nextRowIndex,
                colIndex,
              )
            | _ => loop(offset + 1)
            }
          | None => loop(offset + 1)
          }
        }

      loop(1)
    }
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
    evt =>
      switch evt->ReactEvent.Keyboard.key {
      | "ArrowUp" if evt->ReactEvent.Keyboard.altKey =>
        evt->ReactEvent.Keyboard.preventDefault
        commitNow()
        jumpToIssue(rowIndex, colIndex, -1)

      | "ArrowDown" if evt->ReactEvent.Keyboard.altKey =>
        evt->ReactEvent.Keyboard.preventDefault
        commitNow()
        jumpToIssue(rowIndex, colIndex, 1)

      | "Enter" =>
        evt->ReactEvent.Keyboard.preventDefault
        commitNow()
        jumpToIssue(rowIndex, colIndex, 1)

      | "Tab" =>
        evt->ReactEvent.Keyboard.preventDefault
        commitNow()
        moveTab(rowIndex, colIndex, evt->ReactEvent.Keyboard.shiftKey)

      | "Escape" =>
        evt->ReactEvent.Keyboard.preventDefault
        commitNow()
        focusGridPosition(rowIndex, colIndex)
      | _ => ()
      }

  let isPrintableKey = (evt, key) =>
    key->String.length === 1 &&
      !(evt->ReactEvent.Keyboard.altKey) &&
      !(evt->ReactEvent.Keyboard.ctrlKey) &&
      !(evt->ReactEvent.Keyboard.metaKey)

  let onCellKeyDown = (rowIndex, colIndex, cell: Cell.t) =>
    evt =>
      if !cell.readOnly && isEditorFocused(rowIndex, colIndex) {
        ()
      } else {
        let key = evt->ReactEvent.Keyboard.key

        switch key {
        | "ArrowUp" if evt->ReactEvent.Keyboard.altKey =>
          evt->ReactEvent.Keyboard.preventDefault
          jumpToIssue(rowIndex, colIndex, -1)

        | "ArrowDown" if evt->ReactEvent.Keyboard.altKey =>
          evt->ReactEvent.Keyboard.preventDefault
          jumpToIssue(rowIndex, colIndex, 1)

        | "ArrowUp" =>
          evt->ReactEvent.Keyboard.preventDefault
          moveVertical(rowIndex, colIndex, -1)

        | "ArrowDown" =>
          evt->ReactEvent.Keyboard.preventDefault
          moveVertical(rowIndex, colIndex, 1)

        | "ArrowLeft" =>
          evt->ReactEvent.Keyboard.preventDefault
          moveHorizontal(rowIndex, colIndex, -1)

        | "ArrowRight" =>
          evt->ReactEvent.Keyboard.preventDefault
          moveHorizontal(rowIndex, colIndex, 1)

        | "Enter" =>
          evt->ReactEvent.Keyboard.preventDefault
          jumpToIssue(rowIndex, colIndex, 1)

        | "Tab" =>
          evt->ReactEvent.Keyboard.preventDefault
          moveTab(rowIndex, colIndex, evt->ReactEvent.Keyboard.shiftKey)

        | "Backspace" | "Delete" if !cell.readOnly =>
          evt->ReactEvent.Keyboard.preventDefault
          if cell.value !== "" {
            onCellsChanged([makeChange(~cell, ~row=rowIndex, ~col=colIndex, ~value="")])
            commitNow()
          }

        | key if !cell.readOnly && isPrintableKey(evt, key) =>
          evt->ReactEvent.Keyboard.preventDefault
          onCellsChanged([makeChange(~cell, ~row=rowIndex, ~col=colIndex, ~value=key)])
          scheduleCommit()
          focusEditorLater(~row=rowIndex, ~col=colIndex, ~cursorAtEnd=true)

        | _ => ()
        }
      }

  let onInputChange = (rowIndex, colIndex, cell) =>
    evt => {
      onCellsChanged([
        makeChange(~cell, ~row=rowIndex, ~col=colIndex, ~value=ReactUtils.valueFromEvent(evt)),
      ])
      scheduleCommit()
    }

  let pasteChanges = (rowIndex, colIndex, text) => {
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
  }

  let onCellPaste = (rowIndex, colIndex, cell: Cell.t) =>
    evt =>
      if !cell.readOnly && !isEditorFocused(rowIndex, colIndex) {
        switch evt->Clipboard.getText {
        | Some(text) if text->containsClipboardNewline =>
          evt->ReactEvent.Clipboard.preventDefault
          onCellsChanged([
            makeChange(~cell, ~row=rowIndex, ~col=colIndex, ~value=text->normalizeClipboardNewlines),
          ])
          scheduleCommit()
          focusEditorLater(~row=rowIndex, ~col=colIndex, ~cursorAtEnd=true)
        | Some(text) =>
          let changes = pasteChanges(rowIndex, colIndex, text)

          if changes->Array.length > 0 {
            evt->ReactEvent.Clipboard.preventDefault
            onCellsChanged(changes)
            scheduleCommit()
            focusEditorLater(~row=rowIndex, ~col=colIndex, ~cursorAtEnd=true)
          }
        | None => ()
        }
      }

  let onInputPaste = (rowIndex, colIndex) =>
    evt => {
      let changes = switch evt->Clipboard.getText {
      | Some(text) if text->shouldPasteAcrossGrid => pasteChanges(rowIndex, colIndex, text)
      | None => []
      | Some(_) => []
      }

      if changes->Array.length > 0 {
        evt->ReactEvent.Clipboard.preventDefault
        onCellsChanged(changes)
        scheduleCommit()
      }
    }

  let onCellCopy = (rowIndex, colIndex, cell: Cell.t) =>
    evt =>
      if !isEditorFocused(rowIndex, colIndex) && evt->Clipboard.setText(cell.value) {
        evt->ReactEvent.Clipboard.preventDefault
      }

  let onCellMouseDown = (rowIndex, colIndex, cell: Cell.t) =>
    evt =>
      if !cell.readOnly && !isEditorFocused(rowIndex, colIndex) {
        evt->ReactEvent.Mouse.preventDefault
        commitNow()
        focusGridPosition(rowIndex, colIndex)
      }

  let onCellDoubleClick = (rowIndex, colIndex, cell: Cell.t) =>
    evt =>
      if !cell.readOnly && !isEditorFocused(rowIndex, colIndex) {
        evt->ReactEvent.Mouse.preventDefault
        commitNow()
        focusEditor(~row=rowIndex, ~col=colIndex, ~cursorAtEnd=true)
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
          let meta = getCellMeta(rowIndex, colIndex, cell)
          let className = switch meta {
          | Some(meta) => cell->cellClassName->Cn.addIf(meta.className != "", meta.className)
          | None => cell->cellClassName
          }
          let title = meta->Option.flatMap(meta => meta.title)

          <td
            key={`${rowIndex->Int.toString}-${colIndex->Int.toString}`}
            id={cellId(rowIndex, colIndex)}
            className
            title=?title
            tabIndex=0
            onKeyDown={onCellKeyDown(rowIndex, colIndex, cell)}
            onCopy={onCellCopy(rowIndex, colIndex, cell)}
            onPaste={onCellPaste(rowIndex, colIndex, cell)}
            onMouseDown={onCellMouseDown(rowIndex, colIndex, cell)}
            onDoubleClick={onCellDoubleClick(rowIndex, colIndex, cell)}
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
                  onBlur={_evt => commitNow()}
                />}
          </td>
        })
        ->React.array}
      </tr>
    })
    ->React.array}
  </>
}
