type event = [
  | #mousedown
  | #mouseup
  | #mouseover
]

@new
external make: (event, @as(json`{ bubbles: true }`) _) => Dom.event = "MouseEvent"
