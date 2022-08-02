import React, { PureComponent } from "react";

export default class ValueViewer extends PureComponent {
  render() {
    const { value } = this.props;
    return <span className="value-viewer">{value}</span>;
  }
}
