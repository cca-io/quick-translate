module DataTable = {
  type t

  @send external hashes: t => array<dict<string>> = "hashes"
  @send external raw: t => array<array<string>> = "raw"
  @send external rows: t => array<array<string>> = "rows"
  @send external rowsHash: t => array<dict<string>> = "rowsHash"
  @send external transpose: t => array<array<string>> = "transpose"
}

@module("@cucumber/cucumber")
external given0: (string, unit => unit) => unit = "Given"

@module("@cucumber/cucumber")
external given1: (string, 'a => unit) => unit = "Given"

@module("@cucumber/cucumber")
external given2: (string, ('a, 'b) => unit) => unit = "Given"

@module("@cucumber/cucumber")
external given3: (string, ('a, 'b, 'c) => unit) => unit = "Given"

@module("@cucumber/cucumber")
external given4: (string, ('a, 'b, 'c, 'd) => unit) => unit = "Given"

@module("@cucumber/cucumber")
external then0: (string, unit => unit) => unit = "Then"

@module("@cucumber/cucumber")
external then1: (string, 'a => unit) => unit = "Then"

@module("@cucumber/cucumber")
external then2: (string, ('a, 'b) => unit) => unit = "Then"

@module("@cucumber/cucumber")
external then3: (string, ('a, 'b, 'c) => unit) => unit = "Then"

@module("@cucumber/cucumber")
external then4: (string, ('a, 'b, 'c, 'd) => unit) => unit = "Then"

@module("@cucumber/cucumber")
external when0: (string, unit => unit) => unit = "When"

@module("@cucumber/cucumber")
external when1: (string, 'a => unit) => unit = "When"

@module("@cucumber/cucumber")
external when2: (string, ('a, 'b) => unit) => unit = "When"

@module("@cucumber/cucumber")
external when3: (string, ('a, 'b, 'c) => unit) => unit = "When"

@module("@cucumber/cucumber")
external when4: (string, ('a, 'b, 'c, 'd) => unit) => unit = "When"
