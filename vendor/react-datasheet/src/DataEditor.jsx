import React, { PureComponent } from "react";

export default class DataEditor extends PureComponent {
  constructor(props) {
    super(props);
    this.handleChange = this.handleChange.bind(this);
  }

  componentDidMount() {
    this._input.focus();
  }

  handleChange(e) {
    this.props.onChange(e.target.value);
  }

  render() {
    const { value, onKeyDown } = this.props;
    return (
      <input
        ref={(input) => {
          this._input = input;
        }}
        className="data-editor"
        value={value}
        onChange={this.handleChange}
        onKeyDown={onKeyDown}
      />
    );
  }
}
