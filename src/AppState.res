type mode =
  | Json(Message.jsonLayout)
  | Csv({commentIndex: option<int>, delimiter: string})
  | Other

type dialog =
  | Closed
  | CreateTarget
  | RemoveTarget(string)
  | RemoveSource
  | Help
  | DuplicateTargetImport(string, unit => unit, unit => unit)
  | WarningOrphanedTranslations(string, array<string>)
  | WarningTranslationIncomplete(int, unit => unit)

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
          future: future->Array.slice(~start=1, ~end=future->Array.length),
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
  let defaultMode = Json(Message.ArrayLayout)
  let data = switch localStorage {
  | Array(a) => a->Obj.magic
  | Object(dict) =>
    switch Dict.get(dict, "data") {
    | Some(Array(a)) => a->Obj.magic
    | _ => Source.empty()
    }
  | _ => Source.empty()
  }

  let mode = switch localStorage {
  | Object(dict) =>
    switch Dict.get(dict, "mode") {
    | Some(String("json-array")) => Json(Message.ArrayLayout)
    | Some(String("json-key-value")) => Json(Message.KeyValueLayout)
    | Some(Object(modeDict)) =>
      switch Dict.get(modeDict, "tag") {
      | Some(String("json-array")) => Json(Message.ArrayLayout)
      | Some(String("json-key-value")) => Json(Message.KeyValueLayout)
      | Some(String("other")) => Other
      | Some(String("csv")) =>
        let delimiter =
          modeDict->Dict.get("delimiter")->Option.flatMap(JSON.Decode.string)->Option.getOr(";")
        let commentIndex = switch modeDict->Dict.get("commentIndex") {
        | Some(Number(f)) => Some(f->Int.fromFloat)
        | Some(Null) | None => None
        | _ => None
        }
        Csv({commentIndex, delimiter})
      | _ => defaultMode
      }
    | _ => defaultMode
    }
  | _ => defaultMode
  }

  let useDescription = switch localStorage {
  | Object(dict) =>
    dict->Dict.get("useDescription")->Option.flatMap(JSON.Decode.bool)->Option.getOr(false)
  | _ => false
  }

  {
    data,
    history: {past: [], future: []},
    dialog: Closed,
    mode,
    useDescription,
  }
}

@inline
let key = "quick-translate-data"

let useAppState = () => {
  let (localStorage, setLocalStorage) = Storage.useLocalStorage(
    ~key,
    ~initialValue="{}"->JSON.parseOrThrow,
  )

  let (state, dispatch) = React.useReducerWithMapState(reducer, localStorage, makeInitialState)

  React.useEffect(() => {
    let mode = switch state.mode {
    | Json(Message.ArrayLayout) => JSON.Encode.string("json-array")
    | Json(Message.KeyValueLayout) => JSON.Encode.string("json-key-value")
    | Csv({commentIndex, delimiter}) =>
      JSON.Encode.object(
        Dict.fromArray([
          ("tag", JSON.Encode.string("csv")),
          (
            "commentIndex",
            switch commentIndex {
            | Some(index) => JSON.Encode.int(index)
            | None => JSON.Null
            },
          ),
          ("delimiter", JSON.Encode.string(delimiter)),
        ]),
      )
    | Other => JSON.Encode.string("other")
    }

    Value(
      JSON.Encode.object(
        Dict.fromArray([
          ("data", state.data->Obj.magic),
          ("mode", mode),
          ("useDescription", JSON.Encode.bool(state.useDescription)),
        ]),
      ),
    )->setLocalStorage

    None
  }, (state.data, state.mode, state.useDescription))

  (state, dispatch)
}
