type mode = Json | Other

type dialog =
  | Closed
  | CreateTargetDialog
  | RemoveTargetDialog(string)
  | RemoveSourceDialog

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
  | ToggleCreateTargetDialog
  | OpenRemoveTargetDialog(string)
  | CloseDialog
  | ToggleRemoveSourceDialog

let reducer = (state, action) =>
  switch action {
  | SetMode(mode) => {...state, mode: mode}
  | SetData(data) => {...state, data: data, dialog: Closed}
  | ToggleUseDescription => {...state, useDescription: !state.useDescription}
  | ToggleCreateTargetDialog => {...state, dialog: CreateTargetDialog}
  | OpenRemoveTargetDialog(column) => {...state, dialog: RemoveTargetDialog(column)}
  | CloseDialog => {...state, dialog: Closed}
  | ToggleRemoveSourceDialog => {...state, dialog: RemoveSourceDialog}
  }

let initialState = {
  data: Source.empty(),
  dialog: Closed,
  mode: Other,
  useDescription: false,
}
