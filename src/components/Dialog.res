open ReactUtils

module Internal = {
  @react.component
  let make = (~open_, ~title, ~onClose, ~children) => {
    let escPress = Hooks.useKeyPress("Escape")

    React.useEffect1(() => {
      if escPress {
        onClose()
      }
      None
    }, [escPress])

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
    let onChange = evt => setValue(_ => evt->valueFromEvent)
    let onClick = _evt => onSubmit(value)
    let disabled = value->Js.String.length === 0

    let onKeyPress = evt =>
      evt->doOnEnterHit(() =>
        if value->Js.String.trim !== "" {
          onSubmit(value)
        }
      )

    <Internal open_ title onClose>
      <div> {label} </div>
      <div> <input autoFocus=true type_="text" value onChange onKeyPress /> </div>
      <div> <button disabled onClick> {"OK"->s} </button> </div>
    </Internal>
  }
}

module Confirm = {
  @react.component
  let make = (~open_, ~title, ~label, ~onSubmit, ~onClose) => {
    let enterPress = Hooks.useKeyPress("Enter")

    React.useEffect1(() => {
      if enterPress {
        onSubmit()
      }
      None
    }, [enterPress])

    <Internal open_ title onClose>
      {<div> {label} </div>}
      {<div>
        <button onClick={_evt => onClose()}> {"NO"->s} </button>
        <button onClick={_evt => onSubmit()}> {"YES"->s} </button>
      </div>}
    </Internal>
  }
}
