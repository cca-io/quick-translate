type mode = Json | Other

type dialog =
  | Closed
  | CreateTarget
  | RemoveTarget(string)
  | RemoveSource
  | Help

type state = {
  data: Source.t,
  dialog: dialog,
  mode: mode,
  useDescription: bool,
}

type action =
  | SetMode(mode)
  | SetData(Source.t)
  | ToggleUseDescription
  | SetDialog(dialog)

let reducer = (state, action) =>
  switch action {
  | SetMode(mode) => {...state, mode: mode}
  | SetData(data) => {...state, data: data, dialog: Closed}
  | ToggleUseDescription => {...state, useDescription: !state.useDescription}
  | SetDialog(dialog) => {...state, dialog: dialog}
  }

let initialState = {
  data: Source.empty(),
  dialog: Closed,
  mode: Other,
  useDescription: false,
}
