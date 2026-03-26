type file = Source | Target

let fileNameWithoutExt = fileName => {
  let fileNameArray = fileName->String.split(".")

  fileNameArray->Array.length === 1
    ? fileName
    : fileNameArray->Array.slice(~start=0, ~end=fileNameArray->Array.length - 1)->Array.join("")
}

let download = (~download, ~blankTarget=true, url) => {
  open WebAPI
  let tempLink = document->Document.createElement("a")
  let documentBody = document.body

  tempLink->Element.setAttribute(~qualifiedName="style", ~value="display: none")
  tempLink->Element.setAttribute(~qualifiedName="href", ~value=url)
  tempLink->Element.setAttribute(~qualifiedName="download", ~value=download)

  blankTarget ? tempLink->Element.setAttribute(~qualifiedName="target", ~value="_blank") : ()

  documentBody->HTMLElement.appendChild(tempLink)->ignore
  tempLink->HtmlCast.fromWebElement->HTMLElement.click
  documentBody->HTMLElement.removeChild(tempLink)->ignore
}

let timestampFilename = filename => {
  let timestamp = Date.make()->Date.toISOString->String.split(".")
  let formatted =
    timestamp->Array.getUnsafe(0)->String.replace("T", "_")->String.replaceRegExp(/:/g, "-")

  formatted ++ "-" ++ filename
}
