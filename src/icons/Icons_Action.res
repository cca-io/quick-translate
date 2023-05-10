@react.component
let make = (~size, ~fill="tomato", ~text, ~children) =>
  <svg
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 56 56"
    height={size->Int.toString}>
    {<>
      <path
        d="M48.037 56H7.963A1.463 1.463 0 016.5 54.537V39h43v15.537c0 .808-.655 1.463-1.463 1.463z"
        fill
      />
      <g fill="#fff">
        <text x="50%" y="52" textAnchor="middle" fontWeight="bold" fill="fff">
          {React.string(text)}
        </text>
      </g>
    </>}
    <g fill> {children} </g>
  </svg>
