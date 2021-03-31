type t = Dom.element

@val external create: string => option<t> = "document.createElement"
@val external documentBody: option<t> = "document.body"
@send external setAttribute: (t, string, string) => unit = "setAttribute"
@send external appendChild: (t, t) => unit = "appendChild"
@send external removeChild: (t, t) => unit = "removeChild"
@send external click: t => unit = "click"
@send external focus: t => unit = "focus"
