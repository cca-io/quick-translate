external s: string => React.element = "%identity"

let valueFromEvent = (evt): string => ReactEvent.Form.target(evt)["value"]

let doOnEnterHit = (e: ReactEvent.Keyboard.t, action: unit => unit) => {
  open ReactEvent.Keyboard

  if !(e->altKey) && !(e->ctrlKey) && !(e->metaKey) && !(e->shiftKey) && e->key === "Enter" {
    e->preventDefault
    action()
  }
}

let cancelMouseEvent = (e: ReactEvent.Mouse.t) => {
  e->ReactEvent.Mouse.stopPropagation
  e->ReactEvent.Mouse.preventDefault
}
