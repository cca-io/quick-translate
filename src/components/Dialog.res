open ReactUtils

module Info = {
  @react.component
  let make = (~open_, ~title, ~onClose, ~children) => {
    Hooks.useKeyPress(~omiTextfields=false, "Escape", () => onClose())

    open_
      ? <div className="Dialog">
          <div className="DialogWindow">
            <div className="DialogTop">
              <div className="DialogTitle"> {s(title)} </div>
              <button className="CloseButton" onClick={_evt => onClose()}> {"x"->s} </button>
            </div>
            <div className="DialogContent"> {children} </div>
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
      inputRef.current->Nullable.forEach(input => input->HtmlElement.focus)

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
