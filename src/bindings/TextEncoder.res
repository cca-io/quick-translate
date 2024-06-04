type t

@module("../../vendor/text-encoding/encoding.js") @new external make: string => t = "TextEncoder"

@module("../../vendor/text-encoding/encoding.js") @new
external makeIso8859_1: (
  @as("windows-1252") _,
  @as(json`{ "NONSTANDARD_allowLegacyEncoding": true}`) _,
  unit,
) => t = "TextEncoder"

@send external encode: (t, string) => TypedArray.t<int> = "encode"
