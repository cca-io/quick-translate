type icon = [
  | #csv
  | #help
  | #hideDescription
  | #json
  | #plus
  | #properties
  | #showDescription
  | #strings
  | #trash
  | #xml
]

type size = [#large | #small]

@react.component
let make: (
  ~icon: icon,
  ~title: string,
  ~size: size=?,
  ~onClick: JsxEventU.Mouse.t => unit,
) => Jsx.element
