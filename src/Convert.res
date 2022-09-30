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
  let fromData = (~delimiter: string, data: array<array<DataSheet.Cell.t>>) => {
    let csvData =
      data->Array.map(row => row->Array.map(cell => cell.value))->Papa.unparse(~delimiter)

    `data:text/csv;charset=utf-8,\uFEFF${Js.Global.encodeURIComponent(csvData)}`
  }
}

module Json = {
  let fromData = (data, col) => {
    let colData = data->Source.getColData(col)->Message.toJson->Json.stringifyWithSpace(2)

    "data:text/json;charset=utf-8," ++ Js.Global.encodeURIComponent(colData)
  }

  let fromDataAsBlob = (data, col) => {
    let colData = data->Source.getColData(col)->Message.toJson->Json.stringifyWithSpace(2)

    Blob.fromString([colData])
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

    let enc = TextEncoder.makeIso8859_1()
    let encoded = enc->TextEncoder.encode(propsData)
    [encoded]->Blob.fromTypedArray->Blob.toUrl
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
