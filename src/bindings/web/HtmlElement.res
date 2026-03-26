type t = Dom.element
type style

@val external create: string => option<t> = "document.createElement"
@val external documentBody: option<t> = "document.body"
@send external setAttribute: (t, string, string) => unit = "setAttribute"
@send external appendChild: (t, t) => unit = "appendChild"
@send external removeChild: (t, t) => unit = "removeChild"
@send external click: t => unit = "click"
@send external focus: t => unit = "focus"
@send external select: t => unit = "select"
@get external style: t => style = "style"
@get external scrollHeight: t => int = "scrollHeight"
@send external setProperty: (style, string, string) => unit = "setProperty"

@send external rows: t => array<t> = "rows"
@send external cells: t => array<t> = "cells"
@send external dispatchEvent: (t, Dom.event) => unit = "dispatchEvent"
