type data

@get external data: ReactEvent.Clipboard.t => option<data> = "clipboardData"
@send external getData: (data, string) => string = "getData"
@send external setData: (data, string, string) => unit = "setData"

let getText = evt => evt->data->Option.map(clipboardData => clipboardData->getData("text/plain"))

let setText = (evt, text) =>
  switch evt->data {
  | Some(clipboardData) =>
    clipboardData->setData("text/plain", text)
    true
  | None => false
  }
