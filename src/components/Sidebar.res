module Top = {
  @react.component
  let make = (~children) => <div className="sidebar-top"> {children} </div>
}

module Bottom = {
  @react.component
  let make = (~children) => <div className="sidebar-bottom"> {children} </div>
}

@react.component
let make = (~sourceAvailable, ~children) =>
  sourceAvailable ? <aside className="sidebar"> {children} </aside> : React.null
