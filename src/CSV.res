open Belt

let separator = ";"

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
