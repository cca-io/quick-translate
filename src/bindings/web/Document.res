type t = Dom.document

@val external document: t = "document"
@send external getElementById: (t, string) => option<HtmlElement.t> = "getElementById"
