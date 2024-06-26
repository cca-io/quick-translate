@react.component
let make = (~size, ~fill, ~text=?, ~children) =>
  <svg
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 56 56"
    height={size->Int.toString}>
    <path
      d="M36.985 0H7.963C7.155 0 6.5.655 6.5 1.926V55c0 .345.655 1 1.463 1h40.074c.808 0 1.463-.655 1.463-1V12.978c0-.696-.093-.92-.257-1.085L37.607.257A.884.884 0 0036.985 0z"
      fill="#e9e9e0"
    />
    <path fill="#d9d7ca" d="M37.5.151V12h11.849z" />
    {text->Option.mapOr(React.null, text => <>
      <path
        d="M48.037 56H7.963A1.463 1.463 0 016.5 54.537V39h43v15.537c0 .808-.655 1.463-1.463 1.463z"
        fill
      />
      <g fill="#fff">
        <text x="50%" y="52" textAnchor="middle" fontWeight="bold" fill="fff">
          {React.string(text)}
        </text>
      </g>
    </>)}
    <g fill> {children} </g>
  </svg>
