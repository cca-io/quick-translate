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
  ~onClick: ReactEvent.Mouse.t => unit,
) => Jsx.element
