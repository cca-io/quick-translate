module Spacer = {
  @react.component
  let make = () => <div className="Spacer" />
}

@react.component
let make = (~sourceAvailable, ~children) => {
  sourceAvailable ? <aside className="Sidebar"> {children} </aside> : React.null
}
