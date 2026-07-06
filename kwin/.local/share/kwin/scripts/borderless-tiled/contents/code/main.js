// Borderless Tiled Windows
//
// Removes window decorations while a window is quick-tiled, maximized, or
// fullscreen; restores them when it floats again.
//
// KWin 6.6 has no scriptable `quickTileMode` property — quick-tiled windows are
// placed in a leaf tile, so tiling is detected via `tile` (non-null, and not a
// layout/root tile). `maximizeMode` is readable (0 = none, 3 = full).

function isTiled(w) {
    var t = w.tile;
    var inLeafTile = t !== null && t !== undefined && t.isLayout === false;
    return inLeafTile || w.maximizeMode === 3 || w.fullScreen === true;
}

function applyBorder(w) {
    if (!w || !w.normalWindow || w.specialWindow) {
        return;
    }
    var target = isTiled(w);
    if (w.noBorder !== target) {
        w.noBorder = target;
    }
}

function track(w) {
    if (!w || !w.normalWindow) {
        return;
    }
    applyBorder(w);
    w.quickTileModeChanged.connect(function () { applyBorder(w); });
    w.tileChanged.connect(function () { applyBorder(w); });
    w.maximizedChanged.connect(function () { applyBorder(w); });
    w.fullScreenChanged.connect(function () { applyBorder(w); });
}

var windows = workspace.windowList();
for (var i = 0; i < windows.length; i++) {
    track(windows[i]);
}
workspace.windowAdded.connect(track);
