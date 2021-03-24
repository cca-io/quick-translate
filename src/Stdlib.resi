module Array: {
  module Unsafe = Js.Array2
  external length: array<'a> => int = "%array_length"
  external size: array<'a> => int = "%array_length"
  let get: (array<'a>, int) => option<'a>
  let getExn: (array<'a>, int) => 'a
  external getUnsafe: (array<'a>, int) => 'a = "%array_unsafe_get"
  external getUndefined: (array<'a>, int) => Js.undefined<'a> = "%array_unsafe_get"
  let set: (array<'a>, int, 'a) => bool
  let setExn: (array<'a>, int, 'a) => unit
  external setUnsafe: (array<'a>, int, 'a) => unit = "%array_unsafe_set"
  let shuffleInPlace: array<'a> => unit
  let shuffle: array<'a> => array<'a>
  let reverseInPlace: array<'a> => unit
  let reverse: array<'a> => array<'a>
  @new external makeUninitialized: int => array<Js.undefined<'a>> = "Array"
  @new external makeUninitializedUnsafe: int => array<'a> = "Array"
  let make: (int, 'a) => array<'a>
  let range: (int, int) => array<int>
  let rangeBy: (int, int, ~step: int) => array<int>
  let makeByU: (int, (. int) => 'a) => array<'a>
  let makeBy: (int, int => 'a) => array<'a>
  let makeByAndShuffleU: (int, (. int) => 'a) => array<'a>
  let makeByAndShuffle: (int, int => 'a) => array<'a>
  let zip: (array<'a>, array<'b>) => array<('a, 'b)>
  let zipByU: (array<'a>, array<'b>, (. 'a, 'b) => 'c) => array<'c>
  let zipBy: (array<'a>, array<'b>, ('a, 'b) => 'c) => array<'c>
  let unzip: array<('a, 'b)> => (array<'a>, array<'b>)
  let concat: (array<'a>, array<'a>) => array<'a>
  let concatMany: array<array<'a>> => array<'a>
  let slice: (array<'a>, ~offset: int, ~len: int) => array<'a>
  let sliceToEnd: (array<'a>, int) => array<'a>
  @send external copy: (array<'a>, @as(0) _) => array<'a> = "slice"
  let fill: (array<'a>, ~offset: int, ~len: int, 'a) => unit
  let blit: (~src: array<'a>, ~srcOffset: int, ~dst: array<'a>, ~dstOffset: int, ~len: int) => unit
  let blitUnsafe: (
    ~src: array<'a>,
    ~srcOffset: int,
    ~dst: array<'a>,
    ~dstOffset: int,
    ~len: int,
  ) => unit
  let forEachU: (array<'a>, (. 'a) => unit) => unit
  let forEach: (array<'a>, 'a => unit) => unit
  let mapU: (array<'a>, (. 'a) => 'b) => array<'b>
  let map: (array<'a>, 'a => 'b) => array<'b>
  let getByU: (array<'a>, (. 'a) => bool) => option<'a>
  let getBy: (array<'a>, 'a => bool) => option<'a>
  let getIndexByU: (array<'a>, (. 'a) => bool) => option<int>
  let getIndexBy: (array<'a>, 'a => bool) => option<int>
  let keepU: (array<'a>, (. 'a) => bool) => array<'a>
  let keep: (array<'a>, 'a => bool) => array<'a>
  let keepWithIndexU: (array<'a>, (. 'a, int) => bool) => array<'a>
  let keepWithIndex: (array<'a>, ('a, int) => bool) => array<'a>
  let keepMapU: (array<'a>, (. 'a) => option<'b>) => array<'b>
  let keepMap: (array<'a>, 'a => option<'b>) => array<'b>
  let forEachWithIndexU: (array<'a>, (. int, 'a) => unit) => unit
  let forEachWithIndex: (array<'a>, (int, 'a) => unit) => unit
  let mapWithIndexU: (array<'a>, (. int, 'a) => 'b) => array<'b>
  let mapWithIndex: (array<'a>, (int, 'a) => 'b) => array<'b>
  let partitionU: (array<'a>, (. 'a) => bool) => (array<'a>, array<'a>)
  let partition: (array<'a>, 'a => bool) => (array<'a>, array<'a>)
  let reduceU: (array<'b>, 'a, (. 'a, 'b) => 'a) => 'a
  let reduce: (array<'b>, 'a, ('a, 'b) => 'a) => 'a
  let reduceReverseU: (array<'b>, 'a, (. 'a, 'b) => 'a) => 'a
  let reduceReverse: (array<'b>, 'a, ('a, 'b) => 'a) => 'a
  let reduceReverse2U: (array<'a>, array<'b>, 'c, (. 'c, 'a, 'b) => 'c) => 'c
  let reduceReverse2: (array<'a>, array<'b>, 'c, ('c, 'a, 'b) => 'c) => 'c
  let reduceWithIndexU: (array<'a>, 'b, (. 'b, 'a, int) => 'b) => 'b
  let reduceWithIndex: (array<'a>, 'b, ('b, 'a, int) => 'b) => 'b
  let joinWithU: (array<'a>, string, (. 'a) => string) => string
  let joinWith: (array<'a>, string, 'a => string) => string
  let someU: (array<'a>, (. 'a) => bool) => bool
  let some: (array<'a>, 'a => bool) => bool
  let everyU: (array<'a>, (. 'a) => bool) => bool
  let every: (array<'a>, 'a => bool) => bool
  let every2U: (array<'a>, array<'b>, (. 'a, 'b) => bool) => bool
  let every2: (array<'a>, array<'b>, ('a, 'b) => bool) => bool
  let some2U: (array<'a>, array<'b>, (. 'a, 'b) => bool) => bool
  let some2: (array<'a>, array<'b>, ('a, 'b) => bool) => bool
  let cmpU: (array<'a>, array<'a>, (. 'a, 'a) => int) => int
  let cmp: (array<'a>, array<'a>, ('a, 'a) => int) => int
  let eqU: (array<'a>, array<'a>, (. 'a, 'a) => bool) => bool
  let eq: (array<'a>, array<'a>, ('a, 'a) => bool) => bool
  @set external truncateToLengthUnsafe: (array<'a>, int) => unit = "length"
}

module Map: {
  module String = Belt.Map.String
}

module RegExp: {
  type t = Js.Re.t
  type result = Js.Re.result
  external captures: result => array<Js.nullable<string>> = "%identity"
  @get external index: result => int = "index"
  @get external input: result => string = "input"
  @new external fromString: string => t = "RegExp"
  @new external fromStringWithFlags: (string, ~flags: string) => t = "RegExp"
  @get external flags: t => string = "flags"
  @get external global: t => bool = "global"
  @get external ignoreCase: t => bool = "ignoreCase"
  @get external lastIndex: t => int = "lastIndex"
  @set external setLastIndex: (t, int) => unit = "lastIndex"
  @get external multiline: t => bool = "multiline"
  @get external source: t => string = "source"
  @get external sticky: t => bool = "sticky"
  @get external unicode: t => bool = "unicode"
  @send @return(null_to_opt)
  external exec_: (t, string) => option<result> = "exec"
  @send external test_: (t, string) => bool = "test"
  @new external make: (string, string) => Js.Re.t = "RegExp"
}

module Set: {
  module String = Belt.Set.String
}

module Date = Js.Date
module Float = Belt.Float
module Int = Belt.Int
module Json = Js.Json
module Nullable = Js.Nullable
module Option = Belt.Option
module String = Js.String2
