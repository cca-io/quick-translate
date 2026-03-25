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
    : <div className="no-data-view">
        <div>
          <Icons.Logo height="300" className="app-logo" />
        </div>
        <div> {"No data."->s} </div>
        <div> {"Please drag a language file here."->s} </div>
        <div className="file-types">
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
