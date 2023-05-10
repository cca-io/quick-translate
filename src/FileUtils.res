type file = Source | Target

let fileNameWithoutExt = fileName => {
  let fileNameArray = fileName->String.split(".")

  fileNameArray->Array.length === 1
    ? fileName
    : fileNameArray
      ->Array.slice(~offset=0, ~len=fileNameArray->Array.length - 1)
      ->Array.Unsafe.joinWith("")
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
  let timestamp = Date.make()->Date.toISOString->String.split(".")
  let formatted =
    timestamp->Array.getUnsafe(0)->String.replace("T", "_")->String.replaceByRe(%re("/:/g"), "-")

  formatted ++ "-" ++ filename
}
