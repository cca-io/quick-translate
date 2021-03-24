module Top = {
  @react.component
  let make = (~children) => <div className="SidebarTop"> {children} </div>
}

module Bottom = {
  @react.component
  let make = (~children) => <div className="SidebarBottom"> {children} </div>
}

@react.component
let make = (~sourceAvailable, ~children) =>
  sourceAvailable ? <aside className="Sidebar"> {children} </aside> : React.null
