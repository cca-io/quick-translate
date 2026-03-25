open ReactUtils

@react.component
let make = (~numberOfTranslatedSegments, ~numberOfSourceSegments, ~onClick) => {
  let translationComplete = numberOfTranslatedSegments === numberOfSourceSegments
  let title = translationComplete ? "Translation complete" : "Jump to next untranslated field"

  <button
    title
    ariaLabel=title
    className={`info-tag ${translationComplete ? "complete" : "incomplete"}`}
    onClick=?{translationComplete ? None : Some(onClick)}
  >
    <div className="info-text">
      {if translationComplete {
        "Translation complete"->s
      } else {
        <>
          <b>
            {`${(numberOfSourceSegments - numberOfTranslatedSegments)->Int.toString}${nbsp}`->s}
          </b>
          {"of"->s}
          <b> {`${nbsp}${numberOfSourceSegments->Int.toString}${nbsp}`->s} </b>
          {"translations missing"->React.string}
        </>
      }}
    </div>
  </button>
}
