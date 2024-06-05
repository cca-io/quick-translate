type mode =
  | Json
  | Csv({commentIndex: option<int>, delimiter: string})
  | Other

type dialog =
  | Closed
  | CreateTarget
  | RemoveTarget(string)
  | RemoveSource
  | Help

type history = {
  past: array<Source.t>,
  future: array<Source.t>,
}

type state = {
  data: Source.t,
  history: history,
  dialog: dialog,
  mode: mode,
  useDescription: bool,
}

type action =
  | SetMode(mode)
  | SetData(Source.t)
  | Undo
  | Redo
  | ToggleUseDescription
  | SetDialog(dialog)

let reducer = (state, action) =>
  switch action {
  | SetMode(mode) => {...state, mode}
  | SetData(data) => {
      ...state,
      history: {
        past: state.history.past->Array.concat([state.data]),
        future: [],
      },
      data,
      dialog: Closed,
    }
  | Redo =>
    let {past, future} = state.history
    let next = future[0]

    switch next {
    | Some(nextData) => {
        ...state,
        data: nextData,
        history: {
          past: past->Array.concat([state.data]),
          future: future->Array.sliceToEnd(~start=1),
        },
      }
    | None => state
    }
  | Undo =>
    let {past, future} = state.history
    let lastIndex = past->Array.length - 1
    let previous = past[lastIndex]
    let newPast = past->Array.slice(~start=0, ~end=lastIndex)

    switch previous {
    | Some(previous) if lastIndex > 0 => {
        ...state,
        data: previous,
        history: {
          past: newPast,
          future: [state.data]->Array.concat(future),
        },
      }
    | _ => state
    }
  | ToggleUseDescription => {...state, useDescription: !state.useDescription}
  | SetDialog(dialog) => {...state, dialog}
  }

let makeInitialState = (localStorage: JSON.t) => {
  data: switch localStorage {
  | Array(a) => a->Obj.magic
  | _ => Source.empty()
  },
  history: {past: [], future: []},
  dialog: Closed,
  mode: Other,
  useDescription: false,
}

@inline
let key = "quick-translate-data"

let useAppState = () => {
  let (localStorage, setLocalStorage) = Storage.useLocalStorage(
    ~key,
    ~initialValue="{}"->JSON.parseExn,
  )

  let (state, dispatch) = React.useReducerWithMapState(reducer, localStorage, makeInitialState)

  React.useEffect(() => {
    state.data->Obj.magic->setLocalStorage

    None
  }, [state.data])

  (state, dispatch)
}
