open ReactUtils

module HoverHighlight = {
  @react.component
  let make = (~title, ~onDrop) => {
    let (dragging, onDragOver) = Hooks.useDragOver()

    <div onDragOver onDrop className={"hover-highlight"->Cn.addIf(dragging, "dragging")}>
      {title->s}
    </div>
  }
}

@react.component
let make = (~dragging, ~sourceAvailable, ~onDragLeave, ~handleDrop) =>
  dragging
    ? <div className="import-overlay" onDragLeave>
        <HoverHighlight
          title="Insert source language file here" onDrop={e => handleDrop(e, FileUtils.Source)}
        />
        {sourceAvailable
          ? <HoverHighlight
              title="Insert target language file here" onDrop={e => handleDrop(e, Target)}
            />
          : React.null}
      </div>
    : React.null
