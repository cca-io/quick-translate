open Belt

let toArrayHelper = (~regex, str) => {
  let rows = []
  let pattern = RegExp.make(regex, "gi")

  let rec loop = () => {
    switch pattern->Js.Re.exec_(str) {
    | None => ()
    | Some(re) =>
      let arr = re->Js.Re.captures
      let key = arr[1]->Option.flatMap(key => key->Js.Nullable.toOption)
      let value = arr[2]->Option.flatMap(value => value->Js.Nullable.toOption)

      switch (key, value) {
      | (Some(key), Some(value)) => rows->Js.Array2.push(Message.make(key, value))->ignore
      | _ => ()
      }

      loop()
    }
  }

  loop()

  rows
}

module CSV = {
  let separator = ";"

  let fromData = (data: array<array<DataSheet.Cell.t>>) => {
    let csvData =
      data
      ->Belt.Array.map(row =>
        row->Belt.Array.map(cell => `"${cell.value}"`)->Js.Array2.joinWith(separator)
      )
      ->Js.Array2.joinWith("\n")

    `data:text/csv;charset=utf-8,\uFEFF${Js.Global.encodeURI(csvData)}`
  }

  let regex =
    // Delimiters:
    "(" ++
    separator ++
    "|\r?\n|\r|^)" ++
    // Quoted fields:
    "(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" ++
    // Standard fields:
    "([^" ++
    separator ++ "\r\n]*))"

  let toArray = str => {
    let rows = [[]]
    let pattern = RegExp.make(regex, "gi")

    let rec loop = () => {
      switch pattern->Js.Re.exec_(str) {
      | Some(re) =>
        switch re->Js.Re.captures->Array.get(1) {
        | Some(matchedDelimiter) if matchedDelimiter->Js.Nullable.toOption !== Some(separator) =>
          rows->Js.Array2.push([])->ignore
        | _ => ()
        }

        let matchedValue = switch re->Js.Re.captures->Array.get(2) {
        | Some(matchedValue) =>
          matchedValue
          ->Js.Nullable.toOption
          ->Option.flatMap(str => Some(str->Js.String2.replaceByRe(%re("/[\"\"]+/g"), "\"")))

        | _ => re->Js.Re.captures->Array.get(3)->Option.flatMap(Js.Nullable.toOption)
        }

        rows[rows->Array.length - 1]
        ->Option.getWithDefault([])
        ->Js.Array2.push(matchedValue->Option.getWithDefault(""))
        ->ignore

        loop()

      | None => ()
      }
    }

    loop()

    rows
  }
}

module Json = {
  let fromData = (data, col) => {
    let colData = data->Source.getColData(col)->Message.toJson->Js.Json.stringifyWithSpace(2)

    "data:text/json;charset=utf-8," ++ Js.Global.encodeURIComponent(colData)
  }
}

module Properties = {
  let regex = "(.+|\r?\n|\r|^)\=(.+|\r\n)"

  let fromData = (data, col) => {
    let propsData =
      data
      ->Source.getColData(col)
      ->Array.map(({id, defaultMessage}) => `${id}=${defaultMessage}`)
      ->Js.Array2.joinWith("\n")

    "data:text/plain;charset=ISO-8859-1," ++ Js.Global.encodeURIComponent(propsData)
  }

  let toArray = str => toArrayHelper(~regex, str)
}

module Strings = {
  let fromData = (data, col) => {
    let propsData =
      data
      ->Source.getColData(col)
      ->Array.map(({id, defaultMessage}) => `"${id}" = "${defaultMessage}"`)
      ->Js.Array2.joinWith("\n")

    "data:text/plain;charset=utf-8," ++ Js.Global.encodeURIComponent(propsData)
  }

  let regex = "\"(.+|\r?\n|\r|^)\".\=.\"(.+|\r\n)\";"

  let toArray = str => toArrayHelper(~regex, str)
}
