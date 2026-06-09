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

let modifierKeys = ["Alt", "Control", "Meta", "Shift"]

let isModifierKey = key => modifierKeys->Array.includes(key)

let isEventKeyPressed = (evt, key) =>
  switch key {
  | "Alt" => evt->KeyboardEvent.altKey
  | "Control" => evt->KeyboardEvent.ctrlKey
  | "Meta" => evt->KeyboardEvent.metaKey
  | "Shift" => evt->KeyboardEvent.shiftKey
  | key => evt->KeyboardEvent.key === key
  }

let isShortcutTrigger = (keys, evt) =>
  keys->Array.some(key => !isModifierKey(key) && evt->KeyboardEvent.key === key)

let isShortcutPressed = (keys, evt) =>
  isShortcutTrigger(keys, evt) && keys->Array.every(key => isEventKeyPressed(evt, key))

let useMultiKeyPress = (~omiTextfields=true, keys: array<string>, callback: unit => unit) => {
  React.useEffect(() => {
    let downHandler = evt => {
      if !(evt->KeyboardEvent.repeat) && isTargetOk(~omiTextfields, evt) && isShortcutPressed(keys, evt) {
        evt->KeyboardEvent.preventDefault
        callback()
      }
    }

    addEventListener(Keydown, downHandler)

    Some(() => removeEventListener(Keydown, downHandler))
  }, (callback, keys, omiTextfields))
}
