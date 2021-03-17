type file = Source | Target

let fileNameWithoutExt = fileName => {
  let fileNameArray = fileName->Js.String2.split(".")

  fileNameArray->Array.length === 1
    ? fileName
    : fileNameArray
      ->Belt.Array.slice(~offset=0, ~len=fileNameArray->Array.length - 1)
      ->Js.Array2.joinWith("")
}

let download = (~download, ~blankTarget=true, url) => {
  switch (HtmlElement.create("a"), HtmlElement.documentBody) {
  | (Some(tempLink), Some(documentBody)) =>
    tempLink->HtmlElement.setAttribute("style", "display: none")
    tempLink->HtmlElement.setAttribute("href", url)
    tempLink->HtmlElement.setAttribute("download", download)
    blankTarget ? tempLink->HtmlElement.setAttribute("target", "_blank") : ()

    documentBody->HtmlElement.appendChild(tempLink)
    tempLink->HtmlElement.click
    documentBody->HtmlElement.removeChild(tempLink)

  | _ => ()
  }
}

let timestampFilename = filename => {
  let timestamp = Js.Date.make()->Js.Date.toISOString->Js.String2.split(".")
  let formatted =
    timestamp[0]->Js.String2.replace("T", "_")->Js.String2.replaceByRe(%re("/:/g"), "-")

  formatted ++ "-" ++ filename
}
