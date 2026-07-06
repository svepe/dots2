// Spatial Window Focus
//
//   Alt+1 .. Alt+9        -> focus the N-th window, ordered spatially across all
//                           monitors (x first, y only as a tiebreaker).
//   Meta+Alt+H/J/K/L      -> focus the nearest window to the left/down/up/right.
//
// Operates on normal, non-minimized windows on the current virtual desktop.

function onCurrentDesktop(w) {
    if (w.onAllDesktops) {
        return true;
    }
    var d = w.desktops;
    if (!d || d.length === 0) {
        return true;
    }
    return d.indexOf(workspace.currentDesktop) !== -1;
}

// Normal, visible, focusable windows on the current desktop, sorted x then y.
function windows() {
    var all = workspace.windowList();
    var out = [];
    for (var i = 0; i < all.length; i++) {
        var w = all[i];
        if (!w || !w.normalWindow || w.specialWindow) continue;
        if (w.minimized || w.hidden || w.skipSwitcher) continue;
        if (!onCurrentDesktop(w)) continue;
        out.push(w);
    }
    out.sort(function (a, b) {
        var ga = a.frameGeometry, gb = b.frameGeometry;
        if (ga.x !== gb.x) return ga.x - gb.x;
        return ga.y - gb.y;
    });
    return out;
}

function focus(w) {
    if (w) workspace.activeWindow = w;
}

function center(w) {
    var g = w.frameGeometry;
    return { x: g.x + g.width / 2, y: g.y + g.height / 2 };
}

function focusDirection(dir) {
    var active = workspace.activeWindow;
    var wins = windows();
    if (!active) {
        if (wins.length) focus(wins[0]);
        return;
    }
    var a = center(active);
    var best = null, bestScore = Infinity;
    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        if (w === active) continue;
        var c = center(w);
        var dx = c.x - a.x, dy = c.y - a.y;
        var primary, perp;
        if (dir === "left")       { if (dx >= 0) continue; primary = -dx; perp = Math.abs(dy); }
        else if (dir === "right") { if (dx <= 0) continue; primary =  dx; perp = Math.abs(dy); }
        else if (dir === "up")    { if (dy >= 0) continue; primary = -dy; perp = Math.abs(dx); }
        else                      { if (dy <= 0) continue; primary =  dy; perp = Math.abs(dx); }
        var score = primary + perp * 2; // prefer straight-ahead over diagonal
        if (score < bestScore) { bestScore = score; best = w; }
    }
    if (best) focus(best);
}

// Numbered jump: Alt+1 .. Alt+9
for (var n = 1; n <= 9; n++) {
    (function (idx) {
        registerShortcut("Focus Window " + idx, "Focus Window " + idx, "Alt+" + idx, function () {
            var wins = windows();
            if (wins.length >= idx) focus(wins[idx - 1]);
        });
    })(n);
}

// Directional focus: Meta+Alt+H/J/K/L
registerShortcut("Focus Window Left",  "Focus Window Left",  "Meta+Alt+H", function () { focusDirection("left"); });
registerShortcut("Focus Window Down",  "Focus Window Down",  "Meta+Alt+J", function () { focusDirection("down"); });
registerShortcut("Focus Window Up",    "Focus Window Up",    "Meta+Alt+K", function () { focusDirection("up"); });
registerShortcut("Focus Window Right", "Focus Window Right", "Meta+Alt+L", function () { focusDirection("right"); });
