%%raw("import 'react-datasheet/lib/react-datasheet.css'")
%%raw("import './index.css'")

ReactDOM.querySelector("#root")->Belt.Option.forEach(root => ReactDOM.render(<App />, root))
