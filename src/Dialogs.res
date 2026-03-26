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
    <div className="shortcut">
      <div className="shortcut-keycaps">
        {switch type_ {
        | Simple => kc(keycap)
        | Ctrl => kc("Ctrl") + kc(keycap)
        | CtrlShift => kc("Ctrl") + kc("Shift") + kc(keycap)
        }}
      </div>
      <div> {title->s} </div>
    </div>
}

module Footer = {
  module Separator = {
    @react.component
    let make = () => {(nbsp ++ "|" ++ nbsp)->s}
  }

  @react.component
  let make = (~children) =>
    <div className="dialog-footer">
      <Separator />
      children
      <Separator />
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

  | DuplicateTargetImport(column, onMerge, onReplace) =>
    <Dialog.Info open_=true title={"Target already open"} onClose>
      <div>
        {`The target "${column}" is already open. Do you want to merge the imported translations into the existing column, or replace the existing column with the imported file?`->s}
      </div>
      <div>
        <button
          onClick={_evt => {
            onClose()
            onReplace()
          }}
        >
          {"REPLACE"->s}
        </button>
        <button
          onClick={_evt => {
            onClose()
            onMerge()
          }}
        >
          {"MERGE"->s}
        </button>
      </div>
    </Dialog.Info>

  | WarningOrphanedTranslations(fileName, orphanedIds) =>
    <Dialog.Info open_=true title="Some translations were ignored" onClose>
      <div>
        {switch orphanedIds->Array.length {
        | 1 =>
          `The file "${fileName}" contains 1 translation whose id does not exist in the current source. It was not imported.`->s
        | count =>
          `The file "${fileName}" contains ${count->Int.toString} translations whose ids do not exist in the current source. They were not imported.`->s
        }}
      </div>
      <div>
        {"Ignored ids:"->s}
        <ul>
          {orphanedIds
          ->Array.slice(~start=0, ~end=min(orphanedIds->Array.length, 10))
          ->Array.map(id => <li key=id> {id->s} </li>)
          ->React.array}
        </ul>
      </div>
      {orphanedIds->Array.length > 10
        ? <div>
            {`${(orphanedIds->Array.length - 10)
                ->Int.toString} more ids were omitted from the list.`->s}
          </div>
        : React.null}
    </Dialog.Info>

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
      <Shortcut
        keycap={"Alt + ↑"} title="Jump to previous untranslated field in current column"
      />
      <Shortcut keycap={"Alt + ↓"} title="Jump to next untranslated field in current column" />
      <h4> {"Dialogs"->s} </h4>
      <Shortcut keycap={"Esc"} title="Close dialog" />
      <Shortcut keycap={"Enter"} title="Confirm dialog" />
      <Footer>
        <a
          target="_blank" href="https://github.com/cca-io/quick-translate" rel="noopener noreferrer"
        >
          {"Code"->s}
        </a>
        <Footer.Separator />
        <a
          target="_blank"
          href="https://github.com/cca-io/quick-translate/issues/new"
          rel="noopener noreferrer"
        >
          {"Report an issue"->s}
        </a>
      </Footer>
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
