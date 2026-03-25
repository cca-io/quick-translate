@module("node:assert/strict")
external equal: ('a, 'a) => unit = "equal"

@module("node:assert/strict")
external deepStrictEqual: ('a, 'a) => unit = "deepStrictEqual"
