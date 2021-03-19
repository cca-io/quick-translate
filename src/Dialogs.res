open ReactUtils

@react.component
let make = (~dialog: AppState.dialog, ~data, ~dispatch) => {
  let onClose = _evt => dispatch(AppState.CloseDialog)

  switch dialog {
  | Closed => React.null

  | CreateTargetDialog =>
    <Dialog.Prompt
      open_=true
      title={"Create new target"}
      label={"Enter file name for target"->s}
      onClose
      onSubmit={value => dispatch(SetData([]->Source.add(data, value)))}
    />

  | RemoveTargetDialog(column) =>
    <Dialog.Confirm
      open_=true
      title={"Remove target"}
      label={`Delete column "${column}"?`->s}
      onClose
      onSubmit={_ => dispatch(SetData(data->Source.remove(column)))}
    />

  | RemoveSourceDialog =>
    <Dialog.Confirm
      open_=true
      title={"Remove source"}
      label={`Delete all columns and reset app?`->s}
      onSubmit={_ => dispatch(SetData(Source.empty()))}
      onClose
    />
  }
}
