type colType = Id | Description | Source | Target

let getColType = (index, canToggleDescription) => {
  switch index {
  | 0 => Id
  | 1 => canToggleDescription ? Description : Source
  | 2 => canToggleDescription ? Source : Target
  | _ => Target
  }
}
module ExportButtonRow = {
  @react.component
  let make = (~value, ~onExport) =>
    <div className="ExportButtonRow">
      <IconButton
        title={"Export JSON file"} onClick={evt => onExport(value, File.FileType.Json)} icon=#json
      />
      <IconButton
        title={"Export Properties file"}
        onClick={evt => onExport(value, Properties)}
        icon=#properties
      />
      <IconButton
        title={"Export Strings file"} onClick={evt => onExport(value, Strings)} icon=#strings
      />
      <IconButton
        title={"Export Android XML resources file"} onClick={evt => onExport(value, Xml)} icon=#xml
      />
    </div>
}

module ActionButtonRow = {
  @react.component
  let make = (~value, ~onRemoveTarget) =>
    <div className="ActionButtonRow">
      <IconButton title={"Remove column"} onClick={evt => onRemoveTarget(value)} icon=#trash />
    </div>
}

module IdButtonRow = {
  @react.component
  let make = (~useDescription, ~canToggleDescription, ~onRemoveSource, ~onToggleDescriptions) => {
    let (title, icon) = useDescription
      ? ("Hide descriptions", #hideDescription)
      : ("Show descriptions", #showDescription)

    <div className="IdButtonRow">
      <IconButton onClick=onRemoveSource title={"Remove source"} icon=#trash />
      {canToggleDescription ? <IconButton onClick=onToggleDescriptions title icon /> : React.null}
    </div>
  }
}

@react.component
let make = (~index, ~useDescription, ~canToggleDescription, ~value, ~onExport, ~dispatch) => {
  let colType = getColType(index, canToggleDescription)
  let onToggleDescriptions = _evt => dispatch(AppState.ToggleUseDescription)
  let onRemoveTarget = column => dispatch(SetDialog(RemoveTarget(column)))
  let onRemoveSource = _evt => dispatch(SetDialog(RemoveSource))

  <th>
    <div className="ButtonRow">
      {switch colType {
      | Id =>
        <IdButtonRow useDescription canToggleDescription onRemoveSource onToggleDescriptions />
      | Description => React.null
      | Source => <ExportButtonRow value onExport />
      | Target => <> <ExportButtonRow value onExport /> <ActionButtonRow value onRemoveTarget /> </>
      }}
    </div>
  </th>
}
