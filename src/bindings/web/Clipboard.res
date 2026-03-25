type data

@get external data: ReactEvent.Clipboard.t => option<data> = "clipboardData"
@send external getData: (data, string) => string = "getData"

let getText = evt =>
  evt->data->Option.map(clipboardData => clipboardData->getData("text/plain"))
