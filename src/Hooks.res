let useDragOver = () => {
  let (dragging, setDragging) = React.useState(() => false)

  let onDragOver = (e: ReactEvent.Mouse.t) => {
    e->ReactUtils.cancelMouseEvent
    if !dragging {
      setDragging(_ => true)
    }
  }

  (dragging, onDragOver)
}

let useDrag = () => {
  let (dragging, setDragging) = React.useState(() => false)

  let onDragOver = (e: ReactEvent.Mouse.t) => {
    e->ReactUtils.cancelMouseEvent
    if !dragging {
      setDragging(_ => true)
    }
  }

  let onDragLeave = (e: ReactEvent.Mouse.t) => {
    e->ReactUtils.cancelMouseEvent
    if dragging {
      setDragging(_ => false)
    }
  }

  (dragging, setDragging, onDragOver, onDragLeave)
}

type window = {
  addEventListener: (string, {"key": string} => unit) => unit,
  removeEventListener: (string, {"key": string} => unit) => unit,
}

@val external window: window = "window"

let useKeyPress = (targetKey: string) => {
  let (keyPressed, setKeyPressed) = React.useState(() => false)

  let downHandler = evt => {
    if evt["key"] === targetKey {
      setKeyPressed(_ => true)
    }
  }

  let upHandler = evt => {
    if evt["key"] === targetKey {
      setKeyPressed(_ => false)
    }
  }

  React.useEffect0(() => {
    window.addEventListener("keydown", downHandler)
    window.addEventListener("keyup", upHandler)

    Some(
      () => {
        window.removeEventListener("keydown", downHandler)
        window.removeEventListener("keyup", upHandler)
      },
    )
  })

  keyPressed
}
