module Storage = Dom.Storage2

let subscribe = callback => {
  let handler = _evt => callback()
  addEventListener(Custom("storage"), handler)
  () => removeEventListener(Custom("storage"), handler)
}

let setLocalStorageItem = (key, value) => {
  Console.info("Saved")
  let stringifiedValue = JSON.stringify(value)
  Storage.localStorage->Storage.setItem(key, stringifiedValue)
}

let useLocalStorage = (~key, ~initialValue) => {
  let getSnapshot = () => Storage.localStorage->Storage.getItem(key)
  let store = React.useSyncExternalStore(~subscribe, ~getSnapshot)

  let setState = React.useCallback((nextState: Nullable.t<JSON.t>) => {
    try {
      switch nextState {
      | Value(nextState) => setLocalStorageItem(key, nextState)
      | Null | Undefined => Storage.localStorage->Storage.removeItem(key)
      }
    } catch {
    | JsExn(error) => Console.error(error)
    }
  }, (key, store))

  React.useEffect(() => {
    switch Storage.localStorage->Storage.getItem(key) {
    | None => setLocalStorageItem(key, initialValue)
    | Some(_) => ()
    }

    None
  }, (key, initialValue))

  let newStore = switch store {
  | Some(store) => store->JSON.parseOrThrow
  | None => initialValue
  }

  (newStore, setState)
}
