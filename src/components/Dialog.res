open ReactUtils

module Info = {
  @react.component
  let make = (~open_, ~title, ~onClose, ~children) => {
    Hooks.useKeyPress(~omiTextfields=false, "Escape", () => onClose())

    open_
      ? <div className="dialog">
          <div className="dialog-window">
            <div className="dialog-top">
              <div className="dialog-title"> {s(title)} </div>
              <button className="close-button" onClick={_evt => onClose()}> {"x"->s} </button>
            </div>
            <div className="dialog-content"> {children} </div>
          </div>
        </div>
      : React.null
  }
}

module Prompt = {
  @react.component
  let make = (~open_, ~title, ~label, ~onSubmit, ~onClose) => {
    let (value, setValue) = React.useState(() => "")
    let inputRef: ReactDOM.Ref.currentDomRef = React.useRef(null)
    let onChange = evt => setValue(_ => evt->valueFromEvent)
    let onClick = _evt => onSubmit(value)
    let disabled = value->String.length === 0

    let onKeyPress = evt =>
      evt->doOnEnterHit(() =>
        if value->String.trim !== "" {
          onSubmit(value)
        }
      )

    React.useEffect(() => {
      inputRef.current->Nullable.forEach(input =>
        input->HtmlCast.inputFromLegacyDomElement->WebAPI.HTMLInputElement.focus
      )

      None
    }, [])

    <Info open_ title onClose>
      <div> {label} </div>
      <div>
        <input ref={inputRef->ReactDOM.Ref.domRef} type_="text" value onChange onKeyPress />
      </div>
      <div>
        <button disabled onClick> {"OK"->s} </button>
      </div>
    </Info>
  }
}

module Confirm = {
  @react.component
  let make = (~open_, ~title, ~label, ~onSubmit, ~onClose) => {
    Hooks.useKeyPress(~omiTextfields=false, "Enter", () => onSubmit())

    <Info open_ title onClose>
      {<div> {label} </div>}
      {<div>
        <button onClick={_evt => onClose()}> {"NO"->s} </button>
        <button onClick={_evt => onSubmit()}> {"YES"->s} </button>
      </div>}
    </Info>
  }
}
