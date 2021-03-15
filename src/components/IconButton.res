type icon = [#csv | #json | #properties | #strings | #xml]
type size = [#small | #large]

@react.component
let make = (~icon, ~title, ~size=#small, ~onClick) => {
  let isSmall = size === #small
  let size = isSmall ? 40 : 80

  <button title className={"IconButton"->Cn.addIf(!isSmall, "IconButtonLarge")} onClick>
    {switch icon {
    | #csv => <Icons.Csv size />
    | #json => <Icons.Json size />
    | #properties => <Icons.Properties size />
    | #strings => <Icons.Strings size />
    | #xml => <Icons.Xml size />
    | #trash => <Icons.Trash size />
    | #plus => <Icons.Plus size />
    }}
  </button>
}
