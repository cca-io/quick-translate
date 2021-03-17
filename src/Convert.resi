module CSV: {
  let fromData: array<array<DataSheet.Cell.t>> => string
  let toArray: string => array<array<Js.String2.t>>
}

module Json: {
  let fromData: (array<array<DataSheet.Cell.t>>, string) => string
}

module Properties: {
  let fromData: (array<array<DataSheet.Cell.t>>, string) => string
  let toArray: string => array<Message.t>
}

module Strings: {
  let fromData: (array<array<DataSheet.Cell.t>>, string) => string
  let toArray: string => array<Message.t>
}

module Xml: {
  let fromData: (array<array<DataSheet.Cell.t>>, string) => string
  let toArray: string => array<Message.t>
}
