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

module KeyboardEvent = ReactEvent.Keyboard

let blacklistedTargets = ["INPUT", "TEXTAREA"]

let isTargetOk = (~omiTextfields=true, evt) =>
  !omiTextfields || !(blacklistedTargets->Array.includes((evt->KeyboardEvent.target)["tagName"]))

let useKeyPress = (~omiTextfields=true, targetKey: string, callback: unit => unit) => {
  let (keyPressed, setKeyPressed) = React.useState(() => false)

  let downHandler = evt => {
    if evt->KeyboardEvent.key === targetKey && isTargetOk(~omiTextfields, evt) {
      setKeyPressed(_ => true)
    }
  }

  let upHandler = evt => {
    if evt->KeyboardEvent.key === targetKey && isTargetOk(~omiTextfields, evt) {
      setKeyPressed(_ => false)
    }
  }

  React.useEffect(() => {
    if keyPressed {
      callback()
    }
    None
  }, (callback, keyPressed))

  React.useEffect(() => {
    Window.addKeyboardEventListener("keydown", downHandler)
    Window.addKeyboardEventListener("keyup", upHandler)

    Some(
      () => {
        Window.addKeyboardEventListener("keydown", downHandler)
        Window.addKeyboardEventListener("keyup", upHandler)
      },
    )
  }, [])
}

type action =
  | SetKey(string)
  | RemoveKey(string)
  | Reset

let reducer = (state, action) =>
  switch action {
  | SetKey(key) => state->Belt.Set.String.add(key)
  | RemoveKey(key) => state->Belt.Set.String.remove(key)
  | Reset => Belt.Set.String.empty
  }

let useMultiKeyPress = (~omiTextfields=true, keys: array<string>, callback: unit => unit) => {
  let (keysPressed, dispatch) = React.useReducer(reducer, Belt.Set.String.empty)

  let downHandler = React.useCallback((key, evt) => {
    let eventKey = evt->KeyboardEvent.key
    if !(evt->KeyboardEvent.repeat) && isTargetOk(~omiTextfields, evt) && eventKey === key {
      dispatch(SetKey(key))
    }
  }, [keysPressed])

  let upHandler = React.useCallback((key, evt) => {
    let eventKey = evt->KeyboardEvent.key
    if isTargetOk(~omiTextfields, evt) && eventKey === key {
      dispatch(RemoveKey(key))
    }
  }, [keysPressed])

  React.useEffect(() => {
    if keys->Belt.Set.String.fromArray->Belt.Set.String.eq(keysPressed) {
      callback()
      dispatch(Reset)
    }
    None
  }, (callback, keysPressed))

  React.useEffect(() => {
    keys->Array.forEach(key =>
      Window.addKeyboardEventListener("keydown", evt => downHandler(key, evt))
    )
    keys->Array.forEach(key => Window.addKeyboardEventListener("keyup", evt => upHandler(key, evt)))

    Some(
      () => {
        keys->Array.forEach(key =>
          Window.removeKeyboardEventListener("keydown", evt => downHandler(key, evt))
        )

        keys->Array.forEach(key =>
          Window.removeKeyboardEventListener("keyup", evt => upHandler(key, evt))
        )
      },
    )
  }, [])
}
