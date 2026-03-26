let toArrayHelper = (~pattern, str) => {
  let rows = []

  let rec loop = () => {
    switch pattern->RegExp.exec(str) {
    | None => ()
    | Some(re) =>
      let arr = re->RegExp.Result.matches
      let key = arr->Array.getUnsafe(0)
      let value = arr->Array.getUnsafe(1)

      switch (key, value) {
      | (Some(key), Some(value)) => rows->Array.push(Message.make(key, value))
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

    `data:text/csv;charset=utf-8,\uFEFF${encodeURIComponent(csvData)}`
  }
}

module Json = {
  let fromData = (data, col) => {
    let colData = data->Source.getColData(col)->Message.toJson->JSON.stringify(~space=2)

    "data:text/json;charset=utf-8," ++ encodeURIComponent(colData)
  }

  let fromDataAsBlob = (data, col) => {
    let colData = data->Source.getColData(col)->Message.toJson->JSON.stringify(~space=2)

    Blob.fromString([colData])
  }
}

module Properties = {
  let pattern = /(.+|\r?\n|\r|^)\=(.+|\r\n)/gi

  let fromData = (data, col) => {
    let propsData =
      data
      ->Source.getColData(col)
      ->Array.map(({id, defaultMessage}) => `${id}=${defaultMessage}`)
      ->Array.join("\n")

    let enc = TextEncoder.makeIso8859_1()
    let encoded = enc->TextEncoder.encode(propsData)
    [encoded]->Blob.fromTypedArray->Blob.toUrl
  }

  let toArray = str => toArrayHelper(~pattern, str)
}

module Strings = {
  let pattern = /"([^"]+)"\s*=\s*"([^"]*)";/gi

  let fromData = (data, col) => {
    let propsData =
      data
      ->Source.getColData(col)
      ->Array.map(({id, defaultMessage}) => `"${id}" = "${defaultMessage}";`)
      ->Array.join("\n")

    "data:text/plain;charset=utf-8," ++ encodeURIComponent(propsData)
  }

  let toArray = str => toArrayHelper(~pattern, str)
}

module Xml = {
  let pattern = /<string name="(.+|\r?\n|\r|^)">(.+|\r\n)<\/string>/gi

  let fromData = (data, col) => {
    let propsData =
      data
      ->Source.getColData(col)
      ->Array.map(({id, defaultMessage}) => `    <string name="${id}">${defaultMessage}</string>`)
      ->Array.join("\n")

    let propsData = "<resources>\n" ++ propsData ++ "\n</resources>"

    "data:text/xml;charset=utf-8," ++ encodeURIComponent(propsData)
  }

  let toArray = str => toArrayHelper(~pattern, str)
}
