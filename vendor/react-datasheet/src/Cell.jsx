import React, { PureComponent } from "react";

export default class Cell extends PureComponent {
  render() {
    const {
      cell,
      row,
      col,
      attributesRenderer,
      className,
      style,
      onMouseDown,
      onMouseOver,
      onDoubleClick,
      onContextMenu,
    } = this.props;

    const { colSpan, rowSpan } = cell;
    const attributes = attributesRenderer
      ? attributesRenderer(cell, row, col)
      : {};

    return (
      <td
        className={className}
        onMouseDown={onMouseDown}
        onMouseOver={onMouseOver}
        onDoubleClick={onDoubleClick}
        onTouchEnd={onDoubleClick}
        onContextMenu={onContextMenu}
        colSpan={colSpan}
        rowSpan={rowSpan}
        style={style}
        {...attributes}
      >
        {this.props.children}
      </td>
    );
  }
}

Cell.defaultProps = {
  selected: false,
  editing: false,
  updated: false,
  attributesRenderer: () => {},
};
