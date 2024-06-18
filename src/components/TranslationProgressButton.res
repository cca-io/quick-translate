open ReactUtils

@react.component
let make = (~numberOfTranslatedSegments, ~numberOfSourceSegments, ~onClick) => {
  let translationComplete = numberOfTranslatedSegments === numberOfSourceSegments

  <button
    className={`InfoTag ${translationComplete ? "complete" : "incomplete"}`}
    onClick=?{translationComplete ? None : Some(onClick)}>
    <div className="InfoText">
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
