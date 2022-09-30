type t

@module("jszip") @new external make: unit => t = "default"

@send external file: (t, string, Blob.t) => unit = "file"

type \"type" = [#base64 | #blob]

type options = {\"type": \"type"}

@send external generateAsync: (t, options) => Js.Promise.t<Blob.t> = "generateAsync"

external toFile: t => File.t = "%identity"

make()->Js.log
