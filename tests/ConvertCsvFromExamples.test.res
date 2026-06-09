let csvDataUrlPrefix = "data:text/csv;charset=utf-8,\uFEFF"
let jsonDataUrlPrefix = "data:text/json;charset=utf-8,"
let stringsDataUrlPrefix = "data:text/plain;charset=utf-8,"
let xmlDataUrlPrefix = "data:text/xml;charset=utf-8,"

@val external decodeURIComponent: string => string = "decodeURIComponent"

let readArrayMessages = path =>
  switch path->NodeFs.readUtf8->JSON.parseOrThrow->JSON.Decode.array {
  | Some(messages) => messages->Message.fromJson
  | None => failwith(`Expected "${path}" to decode to a JSON array`)
  }

let readJsonMessages = path =>
  switch path->NodeFs.readUtf8->JSON.parseOrThrow->Message.fromJsonWithLayout {
  | Some((_, messages)) => messages
  | None => failwith(`Expected "${path}" to decode to a supported JSON translation layout`)
  }

let normalizeMessages = messages =>
  messages->Array.map(({Message.id: id, defaultMessage, description}) =>
    Message.make(id, ~description?, defaultMessage)
  )

let decodeDataUrl = (~prefix, url) => url->String.replace(prefix, "")->decodeURIComponent

let exampleColumns = [
  ("example_en", "tests/fixtures/example_en.json", "tests/fixtures/example_en_keyed.json"),
  ("example_de", "tests/fixtures/example_de.json", "tests/fixtures/example_de_keyed.json"),
  ("example_it", "tests/fixtures/example_it.json", "tests/fixtures/example_it_keyed.json"),
]

let exampleData = () =>
  Source.make(readArrayMessages("tests/fixtures/example_en.json"), "example_en.json")
  ->Source.add(readArrayMessages("tests/fixtures/example_de.json"), "example_de.json")
  ->Source.add(readArrayMessages("tests/fixtures/example_it.json"), "example_it.json")

let expectedCsvDataUrl = path =>
  csvDataUrlPrefix ++ encodeURIComponent(path->NodeFs.readUtf8->String.replace("\uFEFF", ""))

let assertColumnRoundTrip = (data, col, expected) =>
  NodeAssert.deepStrictEqual(
    Source.getColData(data, col)->normalizeMessages,
    expected->normalizeMessages,
  )

let roundTripPropertiesColumn = async (data, (col, path, _keyedPath)) => {
  let url = Convert.Properties.fromData(data, col)
  let response = await fetch(url)
  let text = await WebAPI.Response.text(response)
  WebAPI.URL.revokeObjectURL(url)
  let actual = Convert.Properties.toArray(text)

  NodeAssert.deepStrictEqual(actual->normalizeMessages, readArrayMessages(path)->normalizeMessages)
}

let roundTripJsonKeyValueColumn = (data, (col, _path, keyedPath)) => {
  let actual =
    Convert.Json.fromData(data, col, Message.KeyValueLayout)
    ->decodeDataUrl(~prefix=jsonDataUrlPrefix)
    ->JSON.parseOrThrow
    ->Message.fromJsonWithLayout(~layout=Message.KeyValueLayout)
    ->Option.mapOr([], ((_, messages)) => messages)

  NodeAssert.deepStrictEqual(
    actual->normalizeMessages,
    readJsonMessages(keyedPath)->normalizeMessages,
  )
}

let detectJsonLayout = (~layout, messages) =>
  messages
  ->Message.toJsonWithLayout(~layout)
  ->Message.fromJsonWithLayout
  ->Option.getOr((layout, []))

NodeTest.describe("Convert.CSV.fromData", () => {
  NodeTest.test("exports the example JSON fixtures to the checked-in CSV fixture", () => {
    let data = exampleData()
    let actual = Convert.CSV.fromData(~delimiter=";", data)
    let expected = expectedCsvDataUrl("tests/fixtures/example.csv")

    NodeAssert.equal(actual, expected)
  })

  NodeTest.test("round-trips the example CSV fixture back to the original columns", () => {
    let csvRows = switch NodeFs.readUtf8("tests/fixtures/example.csv")
    ->String.replace("\uFEFF", "")
    ->Papa.parse {
    | Success(rows, _) => rows
    | Error => failwith("Expected example.csv to parse successfully")
    }

    let data = Source.fromCsv(csvRows)

    exampleColumns->Array.forEach(
      ((col, path, _keyedPath)) => assertColumnRoundTrip(data, col, readArrayMessages(path)),
    )
  })
})

NodeTest.describe("Source.getOrphanedTargetIds", () => {
  NodeTest.test("returns target ids that are not present in the current source", () => {
    let data = Source.make(
      [Message.make("hello", "Hello"), Message.make("world", "World")],
      "example_en.json",
    )

    let orphanedIds =
      data->Source.getOrphanedTargetIds([
        Message.make("hello", "Hallo"),
        Message.make("extra", "Zusatz"),
        Message.make("world", "Welt"),
        Message.make("old.key", "Alt"),
      ])

    NodeAssert.deepStrictEqual(orphanedIds, ["extra", "old.key"])
  })
})

NodeTest.describe("Source translation status", () => {
  NodeTest.test("counts non-empty validation errors separately from untranslated cells", () => {
    let data =
      Source.make(
        [Message.make("hello", "Hello {name}"), Message.make("empty", "Translate me")],
        "en.json",
      )->Source.add([Message.make("hello", "Hallo"), Message.make("empty", "")], "de.json")

    NodeAssert.equal(Source.getNumberOfUntranslatedSegments(data, 3), 1)
    NodeAssert.equal(Source.getNumberOfInvalidSegments(data, 3), 1)
    NodeAssert.equal(Source.getFirstInvalidCell(data, 3), 1)
  })

  NodeTest.test("does not validate blank untranslated targets", () => {
    let data =
      Source.make([Message.make("hello", "Hello {name}")], "en.json")
      ->Source.add([Message.make("hello", "")], "de.json")

    NodeAssert.deepStrictEqual(Source.getIntlValidation(data, 1, 3), None)
    NodeAssert.equal(Source.getNumberOfUntranslatedSegments(data, 3), 1)
    NodeAssert.equal(Source.getNumberOfInvalidSegments(data, 3), 0)
  })

  NodeTest.test("validates CSV targets against the source column without descriptions", () => {
    let data = Source.fromCsv([
      ["id", "en", "de", "fr"],
      ["hello", "Hello {name}", "Hallo", "Bonjour"],
    ])

    NodeAssert.deepStrictEqual(
      Source.getIntlValidation(data, 1, 2)->Option.map(v => v.IntlValidation.missing),
      Some(["name"]),
    )
    NodeAssert.deepStrictEqual(
      Source.getIntlValidation(data, 1, 3)->Option.map(v => v.IntlValidation.missing),
      Some(["name"]),
    )
    NodeAssert.equal(Source.getNumberOfInvalidSegments(data, 2), 1)
    NodeAssert.equal(Source.getNumberOfInvalidSegments(data, 3), 1)
  })

  NodeTest.test("finds the next validation error after a row and wraps around", () => {
    let data =
      Source.make(
        [
          Message.make("first", "Hello {name}"),
          Message.make("second", "You have {count} messages"),
        ],
        "en.json",
      )->Source.add([Message.make("first", "Hallo"), Message.make("second", "Du hast Nachrichten")], "de.json")

    NodeAssert.equal(Source.getNextInvalidCell(data, 3, 0), 1)
    NodeAssert.equal(Source.getNextInvalidCell(data, 3, 1), 2)
    NodeAssert.equal(Source.getNextInvalidCell(data, 3, 2), 1)
  })

  NodeTest.test("finds the next issue in row order across empty and invalid cells", () => {
    let data =
      Source.make(
        [
          Message.make("first", "Hello"),
          Message.make("second", "Hello {name}"),
          Message.make("third", "Translate me"),
        ],
        "en.json",
      )->Source.add(
        [
          Message.make("first", "Hallo"),
          Message.make("second", "Hallo"),
          Message.make("third", ""),
        ],
        "de.json",
      )

    NodeAssert.equal(Source.getNextIssueCell(data, 3, 1), 2)
    NodeAssert.equal(Source.getNextIssueCell(data, 3, 2), 3)
    NodeAssert.equal(Source.getNextIssueCell(data, 3, 3), 2)
  })
})

NodeTest.describe("IntlValidation.validate", () => {
  NodeTest.test("flags missing ICU placeholders in translations", () => {
    let validation = IntlValidation.validate(
      ~source="Hello {name}, you have {count, plural, one {# message} other {# messages}}",
      ~target="Hallo {name}",
    )

    NodeAssert.deepStrictEqual(
      validation->Option.map(v => v.IntlValidation.missing)->Option.getOr([]),
      ["count"],
    )
  })

  NodeTest.test("accepts nested ICU values when they are preserved", () => {
    let validation = IntlValidation.validate(
      ~source="{gender, select, male {{count, plural, one {He has # file} other {He has # files}}} female {{count, plural, one {She has # file} other {She has # files}}} other {{count, plural, one {They have # file} other {They have # files}}}}",
      ~target="{gender, select, male {{count, plural, one {Er hat # Datei} other {Er hat # Dateien}}} female {{count, plural, one {Sie hat # Datei} other {Sie hat # Dateien}}} other {{count, plural, one {Sie haben # Datei} other {Sie haben # Dateien}}}}",
    )

    NodeAssert.equal(validation, None)
  })

  NodeTest.test("flags missing rich-text tags in translations", () => {
    let validation = IntlValidation.validate(
      ~source="Click <link>here</link> to continue",
      ~target="Klicke hier, um fortzufahren",
    )

    NodeAssert.deepStrictEqual(
      validation->Option.map(v => v.IntlValidation.missing)->Option.getOr([]),
      ["link"],
    )
  })

  NodeTest.test("reports parser errors for invalid ICU translations", () => {
    let validation = IntlValidation.validate(~source="Hello {name}", ~target="Hallo {name")

    NodeAssert.equal(
      validation->Option.flatMap(v => v.IntlValidation.parseError)->Option.isSome,
      true,
    )
  })
})

NodeTest.describe("Convert column formats", () => {
  NodeTest.test("autodetects the source JSON layout", () => {
    let arrayMessages = readJsonMessages("tests/fixtures/example_en.json")
    let keyedMessages = readJsonMessages("tests/fixtures/example_en_keyed.json")
    let (arrayLayout, detectedArrayMessages) =
      "tests/fixtures/example_en.json"
      ->NodeFs.readUtf8
      ->JSON.parseOrThrow
      ->Message.fromJsonWithLayout
      ->Option.getOr((Message.ArrayLayout, []))
    let (keyValueLayout, detectedKeyValueMessages) =
      "tests/fixtures/example_en_keyed.json"
      ->NodeFs.readUtf8
      ->JSON.parseOrThrow
      ->Message.fromJsonWithLayout
      ->Option.getOr((Message.ArrayLayout, []))

    NodeAssert.equal(arrayLayout, Message.ArrayLayout)
    NodeAssert.equal(keyValueLayout, Message.KeyValueLayout)
    NodeAssert.deepStrictEqual(
      detectedArrayMessages->normalizeMessages,
      arrayMessages->normalizeMessages,
    )
    NodeAssert.deepStrictEqual(
      detectedKeyValueMessages->normalizeMessages,
      keyedMessages->normalizeMessages,
    )
  })

  NodeTest.test("round-trips JSON export for every example column", () => {
    let data = exampleData()

    exampleColumns->Array.forEach(
      ((col, path, _keyedPath)) => {
        let actual =
          Convert.Json.fromData(data, col, Message.ArrayLayout)
          ->decodeDataUrl(~prefix=jsonDataUrlPrefix)
          ->JSON.parseOrThrow
          ->JSON.Decode.array
          ->Option.mapOr([], Message.fromJson)

        NodeAssert.deepStrictEqual(
          actual->normalizeMessages,
          readArrayMessages(path)->normalizeMessages,
        )
      },
    )
  })

  NodeTest.test("round-trips key-value JSON export for every example column", () => {
    let data = exampleData()

    exampleColumns->Array.forEach(column => roundTripJsonKeyValueColumn(data, column))
  })

  NodeTest.test("round-trips .strings export for every example column", () => {
    let data = exampleData()

    exampleColumns->Array.forEach(
      ((col, path, _keyedPath)) => {
        let actual =
          Convert.Strings.fromData(data, col)
          ->decodeDataUrl(~prefix=stringsDataUrlPrefix)
          ->Convert.Strings.toArray

        NodeAssert.deepStrictEqual(
          actual->normalizeMessages,
          readArrayMessages(path)->normalizeMessages,
        )
      },
    )
  })

  NodeTest.test("round-trips XML export for every example column", () => {
    let data = exampleData()

    exampleColumns->Array.forEach(
      ((col, path, _keyedPath)) => {
        let actual =
          Convert.Xml.fromData(data, col)
          ->decodeDataUrl(~prefix=xmlDataUrlPrefix)
          ->Convert.Xml.toArray

        NodeAssert.deepStrictEqual(
          actual->normalizeMessages,
          readArrayMessages(path)->normalizeMessages,
        )
      },
    )
  })

  NodeTest.testAsync("round-trips .properties export for every example column", async () => {
    let data = exampleData()
    let tasks = exampleColumns->Array.map(column => roundTripPropertiesColumn(data, column))

    let _ = await Promise.all(tasks)
  })
})
