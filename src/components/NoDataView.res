open ReactUtils

let fileTypes = [
  ("CSV", ""),
  ("JSON", ""),
  ("Java Properties", ""),
  ("Strings", " (XCode)"),
  ("XML", " (Android string resources)"),
]

@react.component
let make = (~sourceAvailable, ~dragging, ~handleUploadClicked) =>
  sourceAvailable || dragging
    ? React.null
    : <div className="NoDataView">
        <div>
          <Icons.Logo height="300" className="AppLogo" />
        </div>
        <div> {"No data."->s} </div>
        <div> {"Please drag a language file here."->s} </div>
        <div className="FileTypes">
          {"Supported file types:"->s}
          <ul>
            {fileTypes
            ->Array.map(((ft, desc)) =>
              <li key=ft>
                <b> {ft->s} </b>
                {desc->s}
              </li>
            )
            ->React.array}
          </ul>
        </div>
        <input type_="file" onChange={event => handleUploadClicked(event, FileUtils.Source)} />
      </div>
