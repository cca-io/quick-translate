type colType = Id | Description | Source | Target

let getColType = (index, canToggleDescription) =>
  switch index {
  | 0 => Id
  | 1 => canToggleDescription ? Description : Source
  | 2 => canToggleDescription ? Source : Target
  | _ => Target
  }

module ExportButtonRow = {
  module JsonExportDropdown = {
    let label = layout =>
      switch layout {
      | Message.ArrayLayout => "Export JSON array (id/defaultMessage)"
      | Message.KeyValueLayout => "Export JSON object (key-value)"
      }

    @react.component
    let make = (~value, ~numberOfUntranslatedSegments, ~numberOfInvalidSegments, ~onExport) => {
      let (isOpen, setIsOpen) = React.useState(() => false)
      let ref: ReactDOM.Ref.currentDomRef = React.useRef(null)

      Hooks.useClickOutside(ref, ~enabled=isOpen, () => setIsOpen(_ => false))

      <div ref={ref->ReactDOM.Ref.domRef} className="icon-dropdown">
        <button
          type_="button"
          className="icon-dropdown-summary"
          title="Export JSON file"
          onClick={_evt => setIsOpen(isOpen => !isOpen)}
        >
          <Icons.Json size=40 />
        </button>
        {isOpen
          ? <div className="icon-dropdown-menu">
              {[Message.ArrayLayout, Message.KeyValueLayout]
              ->Array.map(layout =>
                <button
                  key={label(layout)}
                  type_="button"
                  className="icon-dropdown-item"
                  onClick={_evt => {
                    setIsOpen(_ => false)
                    onExport(
                      value,
                      File.FileType.Json,
                      numberOfUntranslatedSegments,
                      numberOfInvalidSegments,
                      ~jsonLayout=layout,
                    )
                  }}
                >
                  {label(layout)->ReactUtils.s}
                </button>
              )
              ->React.array}
            </div>
          : React.null}
      </div>
    }
  }

  @react.component
  let make = (~value, ~numberOfUntranslatedSegments, ~numberOfInvalidSegments, ~onExport) =>
    <div className="export-button-row">
      <JsonExportDropdown value onExport numberOfUntranslatedSegments numberOfInvalidSegments />
      <IconButton
        title="Export Properties file"
        onClick={_evt =>
          onExport(
            value,
            Properties,
            numberOfUntranslatedSegments,
            numberOfInvalidSegments,
            ~jsonLayout=Message.ArrayLayout,
          )}
        icon=#properties
      />
      <IconButton
        title="Export Strings file"
        onClick={_evt =>
          onExport(
            value,
            Strings,
            numberOfUntranslatedSegments,
            numberOfInvalidSegments,
            ~jsonLayout=Message.ArrayLayout,
          )}
        icon=#strings
      />
      <IconButton
        title="Export Android XML resources file"
        onClick={_evt =>
          onExport(
            value,
            Xml,
            numberOfUntranslatedSegments,
            numberOfInvalidSegments,
            ~jsonLayout=Message.ArrayLayout,
          )}
        icon=#xml
      />
    </div>
}

module ActionButtonRow = {
  @react.component
  let make = (
    ~value,
    ~onRemoveTarget,
    ~onTranslationProgressButtonClick,
    ~numberOfSourceSegments,
    ~numberOfTranslatedSegments,
    ~numberOfInvalidSegments,
  ) => {
    <div className="action-button-row">
      <TranslationProgressButton
        numberOfSourceSegments
        numberOfTranslatedSegments
        numberOfInvalidSegments
        onClick=onTranslationProgressButtonClick
      />
      <IconButton title="Remove column" onClick={_evt => onRemoveTarget(value)} icon=#trash />
    </div>
  }
}

module IdButtonRow = {
  @react.component
  let make = (~useDescription, ~canToggleDescription, ~onRemoveSource, ~onToggleDescriptions) => {
    let (title, icon) = useDescription
      ? ("Hide descriptions", #hideDescription)
      : ("Show descriptions", #showDescription)

    <div className="id-button-row">
      <IconButton onClick=onRemoveSource title="Remove source" icon=#trash />
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
  ~onTranslationProgressButtonClick,
  ~dispatch,
  ~numberOfSourceSegments,
  ~numberOfUntranslatedSegments,
  ~numberOfInvalidSegments,
) => {
  let colType = getColType(index, canToggleDescription)
  let onToggleDescriptions = _evt => dispatch(AppState.ToggleUseDescription)
  let onRemoveTarget = column => dispatch(SetDialog(RemoveTarget(column)))
  let onRemoveSource = _evt => dispatch(SetDialog(RemoveSource))

  let numberOfTranslatedSegments = numberOfSourceSegments - numberOfUntranslatedSegments

  <th>
    <div className="button-row">
      {switch colType {
      | Id =>
        <IdButtonRow useDescription canToggleDescription onRemoveSource onToggleDescriptions />
      | Description => React.null
      | Source =>
        <ExportButtonRow value onExport numberOfUntranslatedSegments numberOfInvalidSegments />
      | Target =>
        <>
          <ExportButtonRow value onExport numberOfUntranslatedSegments numberOfInvalidSegments />
          <ActionButtonRow
            value
            onRemoveTarget
            onTranslationProgressButtonClick
            numberOfSourceSegments
            numberOfTranslatedSegments
            numberOfInvalidSegments
          />
        </>
      }}
    </div>
    <div className="header-col-title"> {value->ReactUtils.s} </div>
  </th>
}
