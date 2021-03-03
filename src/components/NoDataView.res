open ReactUtils

@react.component
let make = (~sourceAvailable, ~dragging) =>
  sourceAvailable || dragging
    ? React.null
    : <div className="NoDataView">
        <span> {"No data."->s} </span>
        <span> {"Please drag a JSON language file or CSV here."->s} </span>
      </div>
