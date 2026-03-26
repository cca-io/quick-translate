let csvDataUrlPrefix = "data:text/csv;charset=utf-8,\uFEFF"
let jsonDataUrlPrefix = "data:text/json;charset=utf-8,"
let stringsDataUrlPrefix = "data:text/plain;charset=utf-8,"
let xmlDataUrlPrefix = "data:text/xml;charset=utf-8,"

@val external decodeURIComponent: string => string = "decodeURIComponent"

let readMessages = path =>
  switch path->NodeFs.readUtf8->JSON.parseOrThrow->JSON.Decode.array {
  | Some(messages) => messages->Message.fromJson
  | None => failwith(`Expected "${path}" to decode to a JSON array`)
  }

let normalizeMessages = messages =>
  messages->Array.map(({Message.id: id, defaultMessage, description}) =>
    Message.make(id, ~description?, defaultMessage)
  )

let decodeDataUrl = (~prefix, url) => url->String.replace(prefix, "")->decodeURIComponent

let exampleColumns = [
  ("example_en", "tests/fixtures/example_en.json"),
  ("example_de", "tests/fixtures/example_de.json"),
  ("example_it", "tests/fixtures/example_it.json"),
]

let exampleData = () =>
  Source.make(readMessages("tests/fixtures/example_en.json"), "example_en.json")
  ->Source.add(readMessages("tests/fixtures/example_de.json"), "example_de.json")
  ->Source.add(readMessages("tests/fixtures/example_it.json"), "example_it.json")

let expectedCsvDataUrl = path =>
  csvDataUrlPrefix ++ encodeURIComponent(path->NodeFs.readUtf8->String.replace("\uFEFF", ""))

let assertColumnRoundTrip = (data, col, expected) =>
  NodeAssert.deepStrictEqual(
    Source.getColData(data, col)->normalizeMessages,
    expected->normalizeMessages,
  )

let roundTripPropertiesColumn = async (data, (col, path)) => {
  let url = Convert.Properties.fromData(data, col)
  let response = await Fetch.fetch(url)
  let text = await Fetch.text(response)
  Fetch.revokeObjectURL(url)
  let actual = Convert.Properties.toArray(text)

  NodeAssert.deepStrictEqual(actual->normalizeMessages, readMessages(path)->normalizeMessages)
}

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
      ((col, path)) => assertColumnRoundTrip(data, col, readMessages(path)),
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

NodeTest.describe("Convert column formats", () => {
  NodeTest.test("round-trips JSON export for every example column", () => {
    let data = exampleData()

    exampleColumns->Array.forEach(
      ((col, path)) => {
        let actual =
          Convert.Json.fromData(data, col)
          ->decodeDataUrl(~prefix=jsonDataUrlPrefix)
          ->JSON.parseOrThrow
          ->JSON.Decode.array
          ->Option.mapOr([], Message.fromJson)

        NodeAssert.deepStrictEqual(actual->normalizeMessages, readMessages(path)->normalizeMessages)
      },
    )
  })

  NodeTest.test("round-trips .strings export for every example column", () => {
    let data = exampleData()

    exampleColumns->Array.forEach(
      ((col, path)) => {
        let actual =
          Convert.Strings.fromData(data, col)
          ->decodeDataUrl(~prefix=stringsDataUrlPrefix)
          ->Convert.Strings.toArray

        NodeAssert.deepStrictEqual(actual->normalizeMessages, readMessages(path)->normalizeMessages)
      },
    )
  })

  NodeTest.test("round-trips XML export for every example column", () => {
    let data = exampleData()

    exampleColumns->Array.forEach(
      ((col, path)) => {
        let actual =
          Convert.Xml.fromData(data, col)
          ->decodeDataUrl(~prefix=xmlDataUrlPrefix)
          ->Convert.Xml.toArray

        NodeAssert.deepStrictEqual(actual->normalizeMessages, readMessages(path)->normalizeMessages)
      },
    )
  })

  NodeTest.testAsync("round-trips .properties export for every example column", async () => {
    let data = exampleData()
    let tasks = exampleColumns->Array.map(column => roundTripPropertiesColumn(data, column))

    let _ = await Promise.all(tasks)
  })
})
