import React, { PureComponent } from "react";

class Sheet extends PureComponent {
  render() {
    return (
      <table className={this.props.className}>
        <tbody>{this.props.children}</tbody>
      </table>
    );
  }
}

export default Sheet;
