open ReactUtils

type colType = Id | Description | Source | Target

let getColType = (index, canToggleDescription) =>
  switch index {
  | 0 => Id
  | 1 => canToggleDescription ? Description : Source
  | 2 => canToggleDescription ? Source : Target
  | _ => Target
  }

module ExportButtonRow = {
  @react.component
  let make = (~value, ~numberOfUntranslatedSegments, ~onExport) =>
    <div className="ExportButtonRow">
      <IconButton
        title={"Export JSON file"}
        onClick={_evt => onExport(value, File.FileType.Json, numberOfUntranslatedSegments)}
        icon=#json
      />
      <IconButton
        title={"Export Properties file"}
        onClick={_evt => onExport(value, Properties, numberOfUntranslatedSegments)}
        icon=#properties
      />
      <IconButton
        title={"Export Strings file"}
        onClick={_evt => onExport(value, Strings, numberOfUntranslatedSegments)}
        icon=#strings
      />
      <IconButton
        title={"Export Android XML resources file"}
        onClick={_evt => onExport(value, Xml, numberOfUntranslatedSegments)}
        icon=#xml
      />
    </div>
}

module ActionButtonRow = {
  @react.component
  let make = (~value, ~onRemoveTarget, ~numberOfSourceSegments, ~numberOfTranslatedSegments) => {
    let translationComplete = numberOfTranslatedSegments === numberOfSourceSegments
    <div className="ActionButtonRow">
      <div className={`InfoTag ${translationComplete ? "complete" : "incomplete"}`}>
        <div className="InfoText">
          {if translationComplete {
            "Translation complete"->s
          } else {
            <>
              <b>
                {`${(numberOfSourceSegments - numberOfTranslatedSegments)->Int.toString}${nbsp}`->s}
              </b>
              {"of"->s}
              <b> {`${nbsp}${numberOfSourceSegments->Int.toString}${nbsp}`->s} </b>
              {"translations missing"->React.string}
            </>
          }}
        </div>
      </div>
      <IconButton title={"Remove column"} onClick={_evt => onRemoveTarget(value)} icon=#trash />
    </div>
  }
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
let make = (
  ~index,
  ~useDescription,
  ~canToggleDescription,
  ~value,
  ~onExport,
  ~dispatch,
  ~numberOfSourceSegments,
  ~numberOfUntranslatedSegments,
) => {
  let colType = getColType(index, canToggleDescription)
  let onToggleDescriptions = _evt => dispatch(AppState.ToggleUseDescription)
  let onRemoveTarget = column => dispatch(SetDialog(RemoveTarget(column)))
  let onRemoveSource = _evt => dispatch(SetDialog(RemoveSource))
  let numberOfTranslatedSegments = numberOfSourceSegments - numberOfUntranslatedSegments

  <th>
    <div className="ButtonRow">
      {switch colType {
      | Id =>
        <IdButtonRow useDescription canToggleDescription onRemoveSource onToggleDescriptions />
      | Description => React.null
      | Source => <ExportButtonRow value onExport numberOfUntranslatedSegments />
      | Target =>
        <>
          <ExportButtonRow value onExport numberOfUntranslatedSegments />
          <ActionButtonRow value onRemoveTarget numberOfSourceSegments numberOfTranslatedSegments />
        </>
      }}
    </div>
  </th>
}
