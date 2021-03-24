module Array = {
  module Unsafe = Js.Array2
  include Belt.Array
}

module Map = {
  module String = Belt.Map.String
}

module RegExp = {
  include Js.Re
  @new external make: (string, string) => Js.Re.t = "RegExp"
}

module Set = {
  module String = Belt.Set.String
}

module Date = Js.Date
module Float = Belt.Float
module Int = Belt.Int
module Json = Js.Json
module Nullable = Js.Nullable
module Option = Belt.Option
module String = Js.String2
