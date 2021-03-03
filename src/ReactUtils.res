external s: string => React.element = "%identity"

let cancelMouseEvent = (e: ReactEvent.Mouse.t) => {
  e->ReactEvent.Mouse.stopPropagation
  e->ReactEvent.Mouse.preventDefault
}
