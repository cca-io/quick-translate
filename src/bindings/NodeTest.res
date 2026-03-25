@module("node:test")
external test: (string, unit => unit) => unit = "test"

@module("node:test")
external testAsync: (string, unit => promise<unit>) => unit = "test"

@module("node:test")
external describe: (string, unit => unit) => unit = "describe"
