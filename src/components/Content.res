@react.component
let make = (~sourceAvailable, ~children) => {
  <div className={"Content"->Cn.addIf(sourceAvailable, "with-margin")}> {children} </div>
}
