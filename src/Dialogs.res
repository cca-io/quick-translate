open ReactUtils

module Shortcut = {
  @react.component
  let make = (~title, ~single=false, ~keycap) =>
    <div className="Shortcut">
      <div className="ShortcutKeycaps">
        {single
          ? React.null
          : <> <kbd> {"Ctrl"->s} </kbd> {" + "->s} <kbd> {"Shift"->s} </kbd> {" + "->s} </>}
        <kbd> {keycap->s} </kbd>
      </div>
      <div> {title->s} </div>
    </div>
}

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
      onSubmit={value => dispatch(SetData(data->Source.add([], value)))}
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
      <h3> {"Keyboard shortcuts"->s} </h3>
      <h4> {"Main view"->s} </h4>
      <Shortcut keycap={"?"} title="Help dialog" />
      <Shortcut keycap={"N"} title="Create a new target" />
      <Shortcut keycap={"R"} title="Remove source" />
      <Shortcut keycap={"D"} title="Toggle Description column" />
      <h4> {"Dialogs"->s} </h4>
      <Shortcut single=true keycap={"Esc"} title="Close dialog" />
      <Shortcut single=true keycap={"Enter"} title="Confirm dialog" />
    </Dialog.Info>
  }
}
