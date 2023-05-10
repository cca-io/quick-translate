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
        <span> {"No data."->s} </span>
        <span> {"Please drag a language file here."->s} </span>
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
