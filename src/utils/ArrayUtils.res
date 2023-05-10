let swap = (arr: array<'a>, indexA: int, indexB: int) => {
  let copy = Array.copy(arr)
  let tempA = copy->Array.getUnsafe(indexA)
  let tempB = copy->Array.getUnsafe(indexB)

  copy->Array.setUnsafe(indexA, tempB)
  copy->Array.setUnsafe(indexB, tempA)

  copy
}
