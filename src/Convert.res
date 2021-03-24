open Stdlib

let toArrayHelper = (~regex, str) => {
  let rows = []
  let pattern = RegExp.make(regex, "gi")

  let rec loop = () => {
    switch pattern->RegExp.exec_(str) {
    | None => ()
    | Some(re) =>
      let arr = re->RegExp.captures
      let key = arr[1]->Option.flatMap(key => key->Nullable.toOption)
      let value = arr[2]->Option.flatMap(value => value->Nullable.toOption)

      switch (key, value) {
      | (Some(key), Some(value)) => rows->Array.Unsafe.push(Message.make(key, value))->ignore
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
      ->Array.map(row =>
        row->Array.map(cell => `"${cell.value}"`)->Array.Unsafe.joinWith(separator)
      )
      ->Array.Unsafe.joinWith("\n")

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
      switch pattern->RegExp.exec_(str) {
      | Some(re) =>
        switch re->RegExp.captures->Array.get(1) {
        | Some(matchedDelimiter) if matchedDelimiter->Nullable.toOption !== Some(separator) =>
          rows->Array.Unsafe.push([])->ignore
        | _ => ()
        }

        let matchedValue = switch re->RegExp.captures->Array.get(2) {
        | Some(matchedValue) =>
          matchedValue
          ->Nullable.toOption
          ->Option.flatMap(str => Some(str->String.replaceByRe(%re("/[\"\"]+/g"), "\"")))

        | _ => re->RegExp.captures->Array.get(3)->Option.flatMap(Nullable.toOption)
        }

        rows[rows->Array.length - 1]
        ->Option.getWithDefault([])
        ->Array.Unsafe.push(matchedValue->Option.getWithDefault(""))
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
    let colData = data->Source.getColData(col)->Message.toJson->Json.stringifyWithSpace(2)

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
      ->Array.Unsafe.joinWith("\n")

    "data:text/plain;charset=ISO-8859-1," ++ Js.Global.encodeURIComponent(propsData)
  }

  let toArray = str => toArrayHelper(~regex, str)
}

module Strings = {
  let regex = "\"(.+|\r?\n|\r|^)\".\=.\"(.+|\r\n)\";"

  let fromData = (data, col) => {
    let propsData =
      data
      ->Source.getColData(col)
      ->Array.map(({id, defaultMessage}) => `"${id}" = "${defaultMessage}"`)
      ->Array.Unsafe.joinWith("\n")

    "data:text/plain;charset=utf-8," ++ Js.Global.encodeURIComponent(propsData)
  }

  let toArray = str => toArrayHelper(~regex, str)
}

module Xml = {
  let regex = "<string name=\"(.+|\r?\n|\r|^)\">(.+|\r\n)<\/string>"

  let fromData = (data, col) => {
    let propsData =
      data
      ->Source.getColData(col)
      ->Array.map(({id, defaultMessage}) => `    <string name="${id}">${defaultMessage}</string>`)
      ->Array.Unsafe.joinWith("\n")

    let propsData = "<resources>\n" ++ propsData ++ "\n</resources>"

    "data:text/xml;charset=utf-8," ++ Js.Global.encodeURIComponent(propsData)
  }

  let toArray = str => toArrayHelper(~regex, str)
}
