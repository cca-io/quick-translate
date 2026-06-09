type messageArgs =
  | Parsed(Belt.Set.String.t)
  | Invalid(string)

type t = {
  missing: array<string>,
  parseError: option<string>,
}

let cache = ref(Belt.Map.String.empty)

let rec collectArgs = (args, elements) =>
  elements->Array.reduce(args, (args, element) =>
    switch element->FormatjsIcuMessageformatParser.Ast.type_ {
    | 1 | 2 | 3 | 4 => args->Belt.Set.String.add(element->FormatjsIcuMessageformatParser.Ast.value)
    | 5 | 6 =>
      let args = args->Belt.Set.String.add(element->FormatjsIcuMessageformatParser.Ast.value)

      element
      ->FormatjsIcuMessageformatParser.Ast.options
      ->Dict.toArray
      ->Array.reduce(args, (args, (_, optionValue)) =>
        collectArgs(args, optionValue->FormatjsIcuMessageformatParser.Ast.optionElements)
      )
    | 8 =>
      collectArgs(
        args->Belt.Set.String.add(element->FormatjsIcuMessageformatParser.Ast.value),
        element->FormatjsIcuMessageformatParser.Ast.children,
      )
    | _ => args
    }
  )

let parseArgs = message => {
  switch cache.contents->Belt.Map.String.get(message) {
  | Some(result) => result
  | None =>
    let result = try {
      collectArgs(Belt.Set.String.empty, message->FormatjsIcuMessageformatParser.parse)->Parsed
    } catch {
    | JsExn(error) => Invalid(error->JsExn.message->Option.getOr("Invalid ICU message"))
    }

    cache.contents = cache.contents->Belt.Map.String.set(message, result)
    result
  }
}

let validate = (~source, ~target) => {
  switch (parseArgs(source), parseArgs(target)) {
  | (Parsed(sourceArgs), Parsed(targetArgs)) =>
    let missing =
      sourceArgs
      ->Belt.Set.String.toArray
      ->Array.filter(arg => !(targetArgs->Belt.Set.String.has(arg)))

    missing->Array.length > 0 ? Some({missing, parseError: None}) : None
  | (Parsed(_), Invalid(parseError)) => Some({missing: [], parseError: Some(parseError)})
  | (Invalid(_), _) => None
  }
}

let message = validation => {
  let missingMessage = switch validation.missing {
  | [] => None
  | missing =>
    Some("Missing ICU values: " ++ missing->Array.map(arg => `{${arg}}`)->Array.join(", "))
  }

  switch (missingMessage, validation.parseError) {
  | (Some(missing), Some(parseError)) => `${missing}. ${parseError}`
  | (Some(missing), None) => missing
  | (None, Some(parseError)) => parseError
  | (None, None) => ""
  }
}
