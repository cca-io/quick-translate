%%raw("import './index.css'")

ReactDOM.querySelector("#root")->Option.forEach(root =>
  ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(<App />)
)
