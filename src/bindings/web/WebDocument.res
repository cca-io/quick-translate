type t = WebAPI.DOMAPI.document
type element = HtmlElement.t

@send @return(nullable)
external getElementById: (t, string) => option<element> = "getElementById"
