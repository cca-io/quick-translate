module Button = {
  @react.component
  let make = (~disabled=false, ~onClick, ~children) => {
    let className = "SidebarButton"->Cn.addIf(disabled, "disabled")

    <button onClick disabled className> {children} </button>
  }
}

module Spacer = {
  @react.component
  let make = () => <div className="Spacer" />
}

@react.component
let make = (~sourceAvailable, ~children) => {
  sourceAvailable ? <aside className="Sidebar"> {children} </aside> : React.null
}
