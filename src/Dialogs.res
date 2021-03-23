open ReactUtils

@react.component
let make = (~dialog: AppState.dialog, ~data, ~dispatch) => {
  let onClose = _evt => dispatch(AppState.SetDialog(Closed))

  switch dialog {
  | Closed => React.null

  | CreateTarget =>
    <Dialog.Prompt
      open_=true
      title={"Create new target"}
      label={"Enter file name for target"->s}
      onClose
      onSubmit={value => dispatch(SetData([]->Source.add(data, value)))}
    />

  | RemoveTarget(column) =>
    <Dialog.Confirm
      open_=true
      title={"Remove target"}
      label={`Delete column "${column}"?`->s}
      onClose
      onSubmit={_ => dispatch(SetData(data->Source.remove(column)))}
    />

  | RemoveSource =>
    <Dialog.Confirm
      open_=true
      title={"Remove source"}
      label={`Delete all columns and reset app?`->s}
      onSubmit={_ => dispatch(SetData(Source.empty()))}
      onClose
    />

  | Help =>
    <Dialog.Info open_=true title={"Help"} onClose>
      <div> {"Keyboard shortcuts"->s} </div>
    </Dialog.Info>
  }
}
