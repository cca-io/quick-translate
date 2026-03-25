let csvDataUrlPrefix = "data:text/csv;charset=utf-8,\uFEFF"

let readMessages = path =>
  switch path->NodeFs.readUtf8->JSON.parseOrThrow->JSON.Decode.array {
  | Some(messages) => messages->Message.fromJson
  | None => failwith(`Expected "${path}" to decode to a JSON array`)
  }

let expectedCsvDataUrl = path => {
  let csv =
    path
    ->NodeFs.readUtf8
    ->String.replace("\uFEFF", "")

  csvDataUrlPrefix ++ encodeURIComponent(csv)
}

NodeTest.describe("Convert.CSV.fromData", () => {
  NodeTest.test("exports the example JSON fixtures to the checked-in CSV fixture", () => {
    let data =
      Source.make(readMessages("examples/example_en.json"), "example_en.json")
      ->Source.add(readMessages("examples/example_de.json"), "example_de.json")
      ->Source.add(readMessages("examples/example_it.json"), "example_it.json")

    let actual = Convert.CSV.fromData(~delimiter=";", data)
    let expected = expectedCsvDataUrl("examples/example.csv")

    NodeAssert.equal(actual, expected)
  })
})
