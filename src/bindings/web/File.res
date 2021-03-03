type t = {
  lastModified: int,
  lastModifiedDate: Js.Date.t,
  name: string,
  size: int,
  \"type": string,
}

module Reader = {
  type reader
  type encoding = [#"UTF-8"]
  type target = {result: string}
  type event = {target: target}

  @new external make: unit => reader = "FileReader"
  @send external readAsText: (reader, t, encoding) => unit = "readAsText"
  @set external setOnload: (reader, event => unit) => unit = "onload"
}

let fromMouseEvent: ReactEvent.Mouse.t => array<t> = e => {
  (e->ReactEvent.Mouse.nativeEvent)["dataTransfer"]["files"]
}

let isJson = (file: t) => file.\"type" === "application/json"

let isCsv = (file: t) => file.\"type" === "text/csv"

let read = (file: t, cb) => {
  let fileReader = Reader.make()
  fileReader->Reader.readAsText(file, #"UTF-8")
  fileReader->Reader.setOnload(e => cb(e.target.result))
}

let resultToJson = result => result->Js.Json.parseExn->Js.Json.decodeArray
