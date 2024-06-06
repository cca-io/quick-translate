open ReactUtils

type shortcut = Simple | Ctrl | CtrlShift

module Shortcut = {
  let add = (a, b) => <>
    a
    {" + "->s}
    b
  </>
  let \"+" = add
  let kc = text => <kbd> {text->s} </kbd>

  @react.component
  let make = (~title, ~type_=Simple, ~keycap) =>
    <div className="Shortcut">
      <div className="ShortcutKeycaps">
        {switch type_ {
        | Simple => kc(keycap)
        | Ctrl => kc("Ctrl") + kc(keycap)
        | CtrlShift => kc("Ctrl") + kc("Shift") + kc(keycap)
        }}
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
      <Shortcut type_=Ctrl keycap={"Z"} title="Undo" />
      <Shortcut type_=CtrlShift keycap={"Z"} title="Redo" />
      <Shortcut type_=CtrlShift keycap={"D"} title="Toggle Description column" />
      <Shortcut type_=CtrlShift keycap={"N"} title="Create a new target" />
      <Shortcut type_=CtrlShift keycap={"R"} title="Remove source" />
      <Shortcut type_=CtrlShift keycap={"?"} title="Help dialog" />
      <h4> {"Dialogs"->s} </h4>
      <Shortcut keycap={"Esc"} title="Close dialog" />
      <Shortcut keycap={"Enter"} title="Confirm dialog" />
    </Dialog.Info>

  | WarningTranslationIncomplete(numberOfUntranslatedSegments, ignoreWarningAndExport) => {
      let title = switch numberOfUntranslatedSegments {
      | 1 => `There is 1 untranslated segment`
      | _ => `There are ${numberOfUntranslatedSegments->Int.toString} untranslated segments`
      }
      <Dialog.Confirm
        open_=true
        title
        label={"Do you really want to continue the export?"->s}
        onSubmit={_ => {
          ignoreWarningAndExport()
          onClose()
        }}
        onClose
      />
    }
  }
}
