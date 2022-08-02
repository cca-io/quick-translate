%%raw("import './vendor/react-datasheet/src/react-datasheet.css'")
%%raw("import './index.css'")

ReactDOM.querySelector("#root")->Belt.Option.forEach(root => ReactDOM.render(<App />, root))
