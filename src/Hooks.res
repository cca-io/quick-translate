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

type window = {
  addEventListener: (string, KeyboardEvent.t => unit) => unit,
  removeEventListener: (string, KeyboardEvent.t => unit) => unit,
}

@val external window: window = "window"

let blacklistedTargets = ["INPUT", "TEXTAREA"]

let isTargetOk = (~omiTextfields=true, evt) =>
  !omiTextfields ||
  !(blacklistedTargets->Array.Unsafe.includes((evt->KeyboardEvent.target)["tagName"]))

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

  React.useEffect2(() => {
    if keyPressed {
      callback()
    }
    None
  }, (callback, keyPressed))

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

  let downHandler = React.Uncurried.useCallback1((key, evt) => {
    let eventKey = evt->KeyboardEvent.key
    if !(evt->KeyboardEvent.repeat) && isTargetOk(~omiTextfields, evt) && eventKey === key {
      dispatch(SetKey(key))
    }
  }, [keysPressed])

  let upHandler = React.Uncurried.useCallback1((key, evt) => {
    let eventKey = evt->KeyboardEvent.key
    if isTargetOk(~omiTextfields, evt) && eventKey === key {
      dispatch(RemoveKey(key))
    }
  }, [keysPressed])

  React.useEffect2(() => {
    if keys->Belt.Set.String.fromArray->Belt.Set.String.eq(keysPressed) {
      callback()
      dispatch(Reset)
    }
    None
  }, (callback, keysPressed))

  React.useEffect0(() => {
    keys->Array.forEach(key => window.addEventListener("keydown", downHandler(. key)))
    keys->Array.forEach(key => window.addEventListener("keyup", upHandler(. key)))

    Some(
      () => {
        keys->Array.forEach(key => window.removeEventListener("keydown", downHandler(. key)))
        keys->Array.forEach(key => window.removeEventListener("keyup", upHandler(. key)))
      },
    )
  })
}
