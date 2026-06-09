let isMac = () => navigator.userAgent->String.includes("Mac")

let primaryModifierKey = () => isMac() ? "Meta" : "Control"

let primaryModifierLabel = () => isMac() ? "Cmd" : "Ctrl"
