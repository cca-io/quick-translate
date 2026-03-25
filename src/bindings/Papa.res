type parseData = array<array<string>>

module Error = {
  type t = {
    \"type": string,
    code: string,
    message: string,
    row: int,
  }
}

module Meta = {
  type t = {
    delimiter: string,
    linebreak: string,
    aborted: bool,
    fields: array<string>,
    truncated: bool,
  }
}

module ParseResults = {
  type result = Success(parseData, string) | Error

  type t = {
    data: parseData,
    error: option<array<Error.t>>,
    meta: Meta.t,
  }

  let toResult: t => result = parseResults =>
    switch parseResults.error {
    | Some(error) if error->Array.length === 0 => Error
    | _ => Success(parseResults.data, parseResults.meta.delimiter)
    }
}

module UnparseConfig = {
  type t = {delimiter: string}
}

type t

@module("papaparse") external default: t = "default"
@get external parseImpl: t => string => ParseResults.t = "parse"
@get external unparseImpl: t => (parseData, UnparseConfig.t) => string = "unparse"

let parse = csv => parseImpl(default)(csv)->ParseResults.toResult
let unparse = (~delimiter=";", parseData) => unparseImpl(default)(parseData, {delimiter: delimiter})
