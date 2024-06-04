type t = {
  lastModified: int,
  lastModifiedDate: Date.t,
  name: string,
  size: int,
  \"type": string,
}

module FileType = {
  type t = Json | Csv | Xml | Strings | Properties

  let fromMimetype = mimeType =>
    switch mimeType {
    | "application/json" => Some(Json)
    | "text/csv" => Some(Csv)
    | "text/xml" => Some(Xml)
    | _ => None
    }

  let fromExtension = extension =>
    switch extension {
    | ".json" => Some(Json)
    | ".csv" => Some(Csv)
    | ".xml" => Some(Xml)
    | ".strings" => Some(Strings)
    | ".properties" => Some(Properties)
    | _ => None
    }

  let toExtension = (fileType: t) =>
    switch fileType {
    | Json => ".json"
    | Csv => ".csv"
    | Xml => ".xml"
    | Strings => ".strings"
    | Properties => ".properties"
    }
}

module FileResult = {
  type t

  external toString: t => string = "%identity"
}

module Reader = {
  type reader
  type encoding = [#"UTF-8" | #"ISO-8859-1"]
  type target = {result: FileResult.t}
  type event = {target: target}

  @new external make: unit => reader = "FileReader"
  @send external readAsText: (reader, t, encoding) => unit = "readAsText"
  @set external setOnload: (reader, event => unit) => unit = "onload"
  @set external setOnError: (reader, event => unit) => unit = "onerror"

  exception FileReadError
}

let fromMouseEvent: ReactEvent.Mouse.t => array<t> = e => {
  (e->ReactEvent.Mouse.nativeEvent)["dataTransfer"]["files"]
}

let fromFormEvent: ReactEvent.Form.t => array<t> = e => {
  (e->ReactEvent.Form.target)["files"]
}

let getExtension = fileName =>
  fileName->String.split(".")->Array.copy->Array.pop->Option.map(ext => "." ++ ext)

let getFileType = (file: t) => {
  let type_ = file.\"type"

  type_->String.length > 0
    ? type_->FileType.fromMimetype
    : file.name->getExtension->Option.flatMap(FileType.fromExtension)
}

let isJson = (file: t) => file.\"type" === "application/json"

let read = (~encoding=#"UTF-8", file: t) =>
  Promise.make((resolve, reject) => {
    let fileReader = Reader.make()
    fileReader->Reader.readAsText(file, encoding)
    fileReader->Reader.setOnload(e => resolve(e.target.result))
    fileReader->Reader.setOnError(_ => reject(Reader.FileReadError))
  })

let resultToJson = (result: FileResult.t) =>
  result->FileResult.toString->JSON.parseExn->JSON.Decode.array
