type t

@new
external fromTypedArray: (array<TypedArray.t<int>>, @as(json`{"type": "text/plain"}`) _) => t =
  "Blob"

@new
external fromString: (array<string>, @as(json`{"type": "text/json"}`) _) => t = "Blob"

@scope("URL")
external toUrl: t => string = "createObjectURL"
