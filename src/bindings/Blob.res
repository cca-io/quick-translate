type t

@new
external fromTypedArray: (
  array<Js.TypedArray2.Uint8Array.t>,
  @as(json`{"type": "text/plain"}`) _,
) => t = "Blob"

@new
external fromString: (array<string>, @as(json`{"type": "text/json"}`) _) => t = "Blob"

@scope("URL")
external toUrl: t => string = "createObjectURL"
