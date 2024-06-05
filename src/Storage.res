open Dom.Storage2

let subscribe = callback => {
  Window.addEventListener("storage", callback)
  () => Window.removeEventListener("storage", callback)
}

let setLocalStorageItem = (key, value) => {
  Console.info("Saved")
  let stringifiedValue = JSON.stringify(value)
  localStorage->setItem(key, stringifiedValue)
}

let useLocalStorage = (~key, ~initialValue) => {
  let getSnapshot = () => localStorage->getItem(key)
  let store = React.useSyncExternalStore(~subscribe, ~getSnapshot)

  let setState = React.useCallback((nextState: Nullable.t<JSON.t>) => {
    try {
      switch nextState {
      | Value(nextState) => setLocalStorageItem(key, nextState)
      | Null | Undefined => localStorage->removeItem(key)
      }
    } catch {
    | Exn.Error(error) => Console.error(error)
    }
  }, (key, store))

  React.useEffect(() => {
    switch localStorage->getItem(key) {
    | None => setLocalStorageItem(key, initialValue)
    | Some(_) => ()
    }

    None
  }, (key, initialValue))

  let newStore = switch store {
  | Some(store) => store->JSON.parseExn
  | None => initialValue
  }

  (newStore, setState)
}
