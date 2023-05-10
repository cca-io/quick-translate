module Cell = {
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
    value: `\u00A0`,
    expr: None,
    readOnly: false,
    width: Some(100),
    className: "",
  }

  let emptyRO = () => {...empty(), readOnly: true}
}

type data = array<array<Cell.t>>

module Change = {
  type t = {cell: Cell.t, col: int, row: int, value: string}
}

module SheetProps = {
  type t = {data: data, className: string, children: React.element}
}

module CellProps = {
  type t = {
    cell: Cell.t,
    className: string,
    onMouseDown: ReactEvent.Mouse.t => unit,
    onMouseOver: ReactEvent.Mouse.t => unit,
    onDoubleClick: ReactEvent.Mouse.t => unit,
    children: React.element,
  }
}

let update = (grid, {Change.row: _row as rowIndex, col, value}) => {
  let row = grid->Array.getUnsafe(rowIndex)
  let cell = row->Array.getUnsafe(col)

  let newCell = {...cell, Cell.value: value->String.trim}
  row->Array.setUnsafe(col, newCell)

  grid->Array.setUnsafe(rowIndex, row)
}

@react.component @module("../../vendor/react-datasheet/src")
external make: (
  ~data: data,
  ~cellRenderer: CellProps.t => React.element=?,
  ~valueRenderer: Cell.t => string,
  ~sheetRenderer: SheetProps.t => React.element=?,
  ~onCellsChanged: array<Change.t> => unit,
) => React.element = "default"
