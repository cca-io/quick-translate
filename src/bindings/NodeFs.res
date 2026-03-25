@module("node:fs")
external readFileSync: (string, string) => string = "readFileSync"

let readUtf8 = path => readFileSync(path, "utf8")
