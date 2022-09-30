open Stdlib

let swapIndex = (data, index) =>
  data->Array.map(row => index !== 1 ? row->Array.swap(index, 1) : row)

let isCommentColumn = text =>
  ["comments", "comment", "description"]->Array.some(str =>
    text->String.toLowerCase->String.includes(str)
  )
