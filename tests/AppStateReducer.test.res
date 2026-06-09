let makeData = value => Source.make([Message.make("greeting", value)], `${value}.json`)

let makeState = data => (
  {
    AppState.data,
    history: {past: [], future: []},
    pendingHistoryEntry: None,
    dialog: Closed,
    mode: Json(Message.ArrayLayout),
    useDescription: false,
  }: AppState.state
)

NodeTest.describe("AppState.reducer", () => {
  NodeTest.test("undo restores the first previous state", () => {
    let initialData = makeData("Hello")
    let changedData = makeData("Hallo")

    let changedState = AppState.reducer(makeState(initialData), SetData(changedData))
    let undoneState = AppState.reducer(changedState, Undo)

    NodeAssert.deepStrictEqual(undoneState.data, initialData)
    NodeAssert.deepStrictEqual(undoneState.history.past, [])
    NodeAssert.deepStrictEqual(undoneState.history.future, [changedData])
  })

  NodeTest.test("redo reapplies the state undone from the first edit", () => {
    let initialData = makeData("Hello")
    let changedData = makeData("Hallo")

    let changedState = AppState.reducer(makeState(initialData), SetData(changedData))
    let undoneState = AppState.reducer(changedState, Undo)
    let redoneState = AppState.reducer(undoneState, Redo)

    NodeAssert.deepStrictEqual(redoneState.data, changedData)
    NodeAssert.deepStrictEqual(redoneState.history.past, [initialData])
    NodeAssert.deepStrictEqual(redoneState.history.future, [])
  })

  NodeTest.test("replace data clears undo history", () => {
    let initialData = makeData("Hello")
    let changedData = makeData("Hallo")
    let replacementData = makeData("Bonjour")
    let stateWithHistory = {
      ...makeState(changedData),
      history: {past: [initialData], future: [makeData("Ciao")]},
    }

    let replacedState = AppState.reducer(stateWithHistory, ReplaceData(replacementData))

    NodeAssert.deepStrictEqual(replacedState.data, replacementData)
    NodeAssert.deepStrictEqual(replacedState.history.past, [])
    NodeAssert.deepStrictEqual(replacedState.history.future, [])
  })

  NodeTest.test("draft edits create one history entry when committed", () => {
    let initialData = makeData("Hello")
    let firstDraft = makeData("H")
    let secondDraft = makeData("Ha")

    let draftState =
      makeState(initialData)
      ->AppState.reducer(EditData(firstDraft))
      ->AppState.reducer(EditData(secondDraft))

    NodeAssert.deepStrictEqual(draftState.data, secondDraft)
    NodeAssert.deepStrictEqual(draftState.history.past, [])

    let committedState = AppState.reducer(draftState, CommitData)
    let undoneState = AppState.reducer(committedState, Undo)

    NodeAssert.deepStrictEqual(committedState.history.past, [initialData])
    NodeAssert.deepStrictEqual(undoneState.data, initialData)
  })

  NodeTest.test("multiple committed edits can be undone one by one", () => {
    let initialData = makeData("Hello")
    let firstEdit = makeData("Hallo")
    let secondEdit = makeData("Bonjour")

    let secondCommittedState =
      makeState(initialData)
      ->AppState.reducer(EditData(firstEdit))
      ->AppState.reducer(CommitData)
      ->AppState.reducer(EditData(secondEdit))
      ->AppState.reducer(CommitData)

    let firstUndoState = AppState.reducer(secondCommittedState, Undo)
    let secondUndoState = AppState.reducer(firstUndoState, Undo)

    NodeAssert.deepStrictEqual(secondCommittedState.history.past, [initialData, firstEdit])
    NodeAssert.deepStrictEqual(firstUndoState.data, firstEdit)
    NodeAssert.deepStrictEqual(firstUndoState.history.future, [secondEdit])
    NodeAssert.deepStrictEqual(secondUndoState.data, initialData)
    NodeAssert.deepStrictEqual(secondUndoState.history.future, [firstEdit, secondEdit])
  })
})

NodeTest.describe("AppState persistence", () => {
  NodeTest.test("persists committed undo history", () => {
    let initialData = makeData("Hello")
    let changedData = makeData("Hallo")
    let futureData = makeData("Bonjour")
    let stateWithHistory = {
      ...makeState(changedData),
      history: {past: [initialData], future: [futureData]},
    }

    let restoredState = AppState.makeInitialState(stateWithHistory->AppState.toLocalStorage)

    NodeAssert.deepStrictEqual(restoredState.data, changedData)
    NodeAssert.deepStrictEqual(restoredState.history.past, [initialData])
    NodeAssert.deepStrictEqual(restoredState.history.future, [futureData])
  })

  NodeTest.test("does not persist pending draft history before commit", () => {
    let initialData = makeData("Hello")
    let changedData = makeData("Hallo")
    let pendingState = {
      ...makeState(changedData),
      history: {past: [initialData], future: []},
      pendingHistoryEntry: Some(initialData),
    }

    let restoredState = AppState.makeInitialState(pendingState->AppState.toLocalStorage)

    NodeAssert.deepStrictEqual(restoredState.data, changedData)
    NodeAssert.deepStrictEqual(restoredState.history.past, [])
    NodeAssert.deepStrictEqual(restoredState.history.future, [])
  })

  NodeTest.test("restores persisted history payloads", () => {
    let data = makeData("current")
    let oldData = makeData("old")
    let futureData = makeData("future")
    let oldPayload =
      JSON.Encode.object(
        Dict.fromArray([
          ("data", data->Obj.magic),
          (
            "history",
            JSON.Encode.object(
              Dict.fromArray([
                ("past", [oldData]->Obj.magic),
                ("future", [futureData]->Obj.magic),
              ]),
            ),
          ),
        ]),
      )

    let restoredState = AppState.makeInitialState(oldPayload)

    NodeAssert.deepStrictEqual(restoredState.data, data)
    NodeAssert.deepStrictEqual(restoredState.history.past, [oldData])
    NodeAssert.deepStrictEqual(restoredState.history.future, [futureData])
  })

  NodeTest.test("persists only the most recent history entries", () => {
    let past = []

    for index in 0 to AppState.maxPersistedHistoryEntries + 4 {
      past->Array.push(makeData(`value-${index->Int.toString}`))
    }

    let stateWithHistory = {
      ...makeState(makeData("current")),
      history: {past, future: []},
    }
    let restoredState = AppState.makeInitialState(stateWithHistory->AppState.toLocalStorage)
    let expectedFirstPersistedEntry =
      past->Array.getUnsafe(past->Array.length - AppState.maxPersistedHistoryEntries)

    NodeAssert.deepStrictEqual(
      restoredState.history.past->Array.length,
      AppState.maxPersistedHistoryEntries,
    )
    NodeAssert.deepStrictEqual(
      restoredState.history.past->Array.getUnsafe(0),
      expectedFirstPersistedEntry,
    )
  })
})
