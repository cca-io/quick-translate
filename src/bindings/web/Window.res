@val external prompt: string => Js.Null.t<string> = "window.prompt"
let prompt = str => prompt(str)->Js.Null.toOption

@val external confirm: string => bool = "window.confirm"
