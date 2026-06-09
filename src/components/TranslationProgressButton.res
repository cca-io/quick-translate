open ReactUtils

@react.component
let make = (
  ~numberOfTranslatedSegments,
  ~numberOfSourceSegments,
  ~numberOfInvalidSegments,
  ~onClick,
) => {
  let numberOfUntranslatedSegments = numberOfSourceSegments - numberOfTranslatedSegments
  let translationComplete =
    numberOfTranslatedSegments === numberOfSourceSegments && numberOfInvalidSegments === 0
  let title = if translationComplete {
    "Translation complete"
  } else if numberOfUntranslatedSegments > 0 {
    "Jump to next untranslated field"
  } else {
    "Jump to next validation error"
  }

  <button
    title
    ariaLabel=title
    className={`info-tag ${translationComplete ? "complete" : "incomplete"}`}
    onMouseDown={evt => evt->ReactEvent.Mouse.preventDefault}
    onClick=?{translationComplete ? None : Some(onClick)}
  >
    <div className="info-text">
      {if translationComplete {
        "Translation complete"->s
      } else if numberOfInvalidSegments > 0 && numberOfUntranslatedSegments === 0 {
        <>
          <b> {`${numberOfInvalidSegments->Int.toString}${nbsp}`->s} </b>
          {numberOfInvalidSegments === 1
            ? "validation error"->s
            : "validation errors"->s}
        </>
      } else if numberOfInvalidSegments > 0 {
        <>
          <b> {`${numberOfUntranslatedSegments->Int.toString}${nbsp}`->s} </b>
          {"missing,"->s}
          <b> {`${nbsp}${numberOfInvalidSegments->Int.toString}${nbsp}`->s} </b>
          {numberOfInvalidSegments === 1
            ? "validation error"->s
            : "validation errors"->s}
        </>
      } else {
        <>
          <b>
            {`${numberOfUntranslatedSegments->Int.toString}${nbsp}`->s}
          </b>
          {"of"->s}
          <b> {`${nbsp}${numberOfSourceSegments->Int.toString}${nbsp}`->s} </b>
          {"translations missing"->React.string}
        </>
      }}
    </div>
  </button>
}
