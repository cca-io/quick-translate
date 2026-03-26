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

let useClickOutside = (ref: ReactDOM.Ref.currentDomRef, ~enabled=true, callback: unit => unit) => {
  React.useEffect(() => {
    if enabled {
      open WebAPI

      let handler = (evt: EventAPI.event) =>
        switch (ref.current, evt.target->Null.toOption) {
        | (Value(element), Some(target)) =>
          if (
            !(
              element
              ->HtmlCast.nodeFromLegacyDomElement
              ->Node.contains(target->HtmlCast.nodeFromEventTarget)
            )
          ) {
            callback()
          }
        | _ => ()
        }

      addEventListener(Pointerdown, handler)

      Some(() => removeEventListener(Pointerdown, handler))
    } else {
      None
    }
  }, (enabled, callback, ref))
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

let isTargetOk = (~omiTextfields, evt) =>
  !omiTextfields || !(blacklistedTargets->Array.includes((evt->KeyboardEvent.target)["tagName"]))

let useKeyPress = (~omiTextfields, targetKey: string, callback: unit => unit) => {
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
    addEventListener(Keydown, downHandler)
    addEventListener(Keyup, upHandler)

    Some(
      () => {
        removeEventListener(Keydown, downHandler)
        removeEventListener(Keyup, upHandler)
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
    keys->Array.forEach(key => addEventListener(Keydown, evt => downHandler(key, evt)))
    keys->Array.forEach(key => addEventListener(Keyup, evt => upHandler(key, evt)))

    Some(
      () => {
        keys->Array.forEach(key => removeEventListener(Keydown, evt => downHandler(key, evt)))

        keys->Array.forEach(key => removeEventListener(Keyup, evt => upHandler(key, evt)))
      },
    )
  }, [])
}
