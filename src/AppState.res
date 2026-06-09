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
  | WarningTranslationIncomplete(int, int, unit => unit)

type history = {
  past: array<Source.t>,
  future: array<Source.t>,
}

type state = {
  data: Source.t,
  history: history,
  pendingHistoryEntry: option<Source.t>,
  dialog: dialog,
  mode: mode,
  useDescription: bool,
}

type action =
  | SetMode(mode)
  | SetData(Source.t)
  | EditData(Source.t)
  | CommitData
  | ReplaceData(Source.t)
  | Undo
  | Redo
  | ToggleUseDescription
  | SetDialog(dialog)

let emptyHistory = () => {past: [], future: []}

let maxPersistedHistoryEntries = 20
let maxPersistedLocalStorageChars = 2000000

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
      pendingHistoryEntry: None,
      dialog: Closed,
    }
  | EditData(data) => {
      ...state,
      data,
      pendingHistoryEntry: switch state.pendingHistoryEntry {
      | Some(_) as pendingHistoryEntry => pendingHistoryEntry
      | None => Some(state.data)
      },
    }
  | CommitData =>
    switch state.pendingHistoryEntry {
    | Some(historyEntry) => {
        ...state,
        history: {
          past: state.history.past->Array.concat([historyEntry]),
          future: [],
        },
        pendingHistoryEntry: None,
      }
    | None => state
    }
  | ReplaceData(data) => {
      ...state,
      history: emptyHistory(),
      data,
      pendingHistoryEntry: None,
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
        pendingHistoryEntry: None,
      }
    | None => state
    }
  | Undo =>
    let {past, future} = state.history
    let lastIndex = past->Array.length - 1
    let previous = past[lastIndex]
    let newPast = past->Array.slice(~start=0, ~end=lastIndex)

    switch previous {
    | Some(previous) => {
        ...state,
        data: previous,
        history: {
          past: newPast,
          future: [state.data]->Array.concat(future),
        },
        pendingHistoryEntry: None,
      }
    | _ => state
    }
  | ToggleUseDescription => {...state, useDescription: !state.useDescription}
  | SetDialog(dialog) => {...state, dialog}
  }

let decodeHistoryArray = (json: option<JSON.t>) =>
  switch json {
  | Some(Array(a)) => a->Obj.magic
  | _ => []
  }

let decodeHistory = (localStorage: JSON.t) =>
  switch localStorage {
  | Object(dict) =>
    switch dict->Dict.get("history") {
    | Some(Object(historyDict)) => {
        past: historyDict->Dict.get("past")->decodeHistoryArray,
        future: historyDict->Dict.get("future")->decodeHistoryArray,
      }
    | _ => emptyHistory()
    }
  | _ => emptyHistory()
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
    history: localStorage->decodeHistory,
    pendingHistoryEntry: None,
    dialog: Closed,
    mode,
    useDescription,
  }
}

@inline
let key = "quick-translate-data"

let encodeMode = mode =>
  switch mode {
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

let encodeHistory = history =>
  JSON.Encode.object(
    Dict.fromArray([
      ("past", history.past->Obj.magic),
      ("future", history.future->Obj.magic),
    ]),
  )

let encodeLocalStorage = (state, history) => {
  let entries = [
    ("data", state.data->Obj.magic),
    ("mode", state.mode->encodeMode),
    ("useDescription", JSON.Encode.bool(state.useDescription)),
  ]

  JSON.Encode.object(
    Dict.fromArray(
      switch history {
      | Some(history) => entries->Array.concat([("history", history->encodeHistory)])
      | None => entries
      },
    ),
  )
}

let trimHistoryEntryCount = history => {
  let pastLength = history.past->Array.length
  let futureLength = history.future->Array.length

  {
    past: history.past->Array.slice(
      ~start=pastLength > maxPersistedHistoryEntries
        ? pastLength - maxPersistedHistoryEntries
        : 0,
      ~end=pastLength,
    ),
    future: history.future->Array.slice(
      ~start=0,
      ~end=futureLength > maxPersistedHistoryEntries
        ? maxPersistedHistoryEntries
        : futureLength,
    ),
  }
}

let isHistoryEmpty = history =>
  history.past->Array.length === 0 && history.future->Array.length === 0

let dropOldestHistoryEntry = history =>
  if history.past->Array.length > 0 {
    {
      ...history,
      past: history.past->Array.slice(~start=1, ~end=history.past->Array.length),
    }
  } else if history.future->Array.length > 0 {
    {
      ...history,
      future: history.future->Array.slice(~start=0, ~end=history.future->Array.length - 1),
    }
  } else {
    history
  }

let boundedPersistedHistory = state =>
  switch state.pendingHistoryEntry {
  | Some(_) => None
  | None =>
    let rec fit = history => {
      let payload = encodeLocalStorage(state, Some(history))

      if isHistoryEmpty(history) {
        None
      } else if payload->JSON.stringify->String.length <= maxPersistedLocalStorageChars {
        Some(history)
      } else {
        fit(history->dropOldestHistoryEntry)
      }
    }

    fit(state.history->trimHistoryEntryCount)
  }

let toLocalStorage = state => state->encodeLocalStorage(state->boundedPersistedHistory)

let useAppState = () => {
  let (localStorage, setLocalStorage) = Storage.useLocalStorage(
    ~key,
    ~initialValue="{}"->JSON.parseOrThrow,
  )

  let (state, dispatch) = React.useReducerWithMapState(reducer, localStorage, makeInitialState)

  React.useEffect(() => {
    Value(state->toLocalStorage)->setLocalStorage

    None
  }, (state.data, state.history, state.pendingHistoryEntry, state.mode, state.useDescription))

  (state, dispatch)
}
