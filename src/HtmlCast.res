external fromWebElement: WebAPI.DOMAPI.element => WebAPI.DOMAPI.htmlElement = "%identity"
external inputFromWebElement: WebAPI.DOMAPI.element => WebAPI.DOMAPI.htmlInputElement = "%identity"
external nodeFromEventTarget: WebAPI.EventAPI.eventTarget => WebAPI.DOMAPI.node = "%identity"
external nodeFromLegacyDomElement: Dom.element => WebAPI.DOMAPI.node = "%identity"
external inputFromLegacyDomElement: Dom.element => WebAPI.DOMAPI.htmlInputElement = "%identity"
external textAreaFromLegacyDomElement: Dom.element => WebAPI.DOMAPI.htmlTextAreaElement =
  "%identity"
