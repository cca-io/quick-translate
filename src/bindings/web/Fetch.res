type response

@val external fetch: string => promise<response> = "fetch"

@send external text: response => promise<string> = "text"

@scope("URL") @val external revokeObjectURL: string => unit = "revokeObjectURL"
