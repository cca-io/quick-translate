module Cell = {
  type t = {
    value: string,
    expr: option<string>,
    readOnly: bool,
    width: option<int>,
    className: string,
  }

  let make = (~expr=None, ~readOnly=false, ~className="", value) => {
    value: value,
    expr: expr,
    readOnly: readOnly,
    width: None,
    className: className,
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

let update = (grid, {Change.row: row, col, value, _}) =>
  grid[row][col] = {...grid[row][col], Cell.value: value}

@react.component @module("react-datasheet")
external make: (
  ~data: data,
  ~valueRenderer: Cell.t => string,
  ~sheetRenderer: SheetProps.t => React.element=?,
  ~onCellsChanged: array<Change.t> => unit,
) => React.element = "default"
