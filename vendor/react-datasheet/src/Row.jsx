import React, { PureComponent } from "react";

class Row extends PureComponent {
  render() {
    return <tr>{this.props.children}</tr>;
  }
}

export default Row;
