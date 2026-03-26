type t = {
  id: string,
  defaultMessage: string,
  description: option<string>,
}

type jsonLayout =
  | ArrayLayout
  | KeyValueLayout

let make = (id, ~description=?, defaultMessage) => {
  id,
  defaultMessage,
  description,
}

external toJson: array<t> => JSON.t = "%identity"
external fromJson: array<JSON.t> => array<t> = "%identity"

let toJsonWithLayout = (~layout, messages) =>
  switch layout {
  | ArrayLayout => messages->toJson
  | KeyValueLayout =>
    messages
    ->Array.map(({id, defaultMessage}) => (id, JSON.Encode.string(defaultMessage)))
    ->Dict.fromArray
    ->JSON.Encode.object
  }

let fromJsonWithLayout = (~layout=?, json) => {
  let decode = (layout, json) =>
    switch layout {
    | ArrayLayout => json->JSON.Decode.array->Option.map(messages => (layout, messages->fromJson))
    | KeyValueLayout =>
      json
      ->JSON.Decode.object
      ->Option.flatMap(dict =>
        dict
        ->Dict.toArray
        ->Array.reduce(Some([]), (acc, (id, value)) =>
          switch (acc, value->JSON.Decode.string) {
          | (Some(messages), Some(defaultMessage)) =>
            Some(messages->Array.concat([make(id, defaultMessage)]))
          | _ => None
          }
        )
        ->Option.map(messages => (layout, messages))
      )
    }

  switch layout {
  | Some(layout) => decode(layout, json)
  | None =>
    switch decode(ArrayLayout, json) {
    | Some(decoded) => Some(decoded)
    | None => decode(KeyValueLayout, json)
    }
  }
}
