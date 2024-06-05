@val
external addEventListener: (string, unit => unit) => unit = "window.addEventListener"

@val
external removeEventListener: (string, unit => unit) => unit = "window.removeEventListener"

@val
external addKeyboardEventListener: (string, ReactEvent.Keyboard.t => unit) => unit =
  "window.addEventListener"

@val
external removeKeyboardEventListener: (string, ReactEvent.Keyboard.t => unit) => unit =
  "window.removeEventListener"
