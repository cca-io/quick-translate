@react.component
let make = (~sourceAvailable, ~children) => {
  <div className={"content"->Cn.addIf(sourceAvailable, "with-margin")}> {children} </div>
}
