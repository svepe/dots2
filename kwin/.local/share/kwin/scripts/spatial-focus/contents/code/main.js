// Spatial Window Focus
//
//   Alt+1 .. Alt+9        -> focus the N-th window, ordered spatially across all
//                           monitors (x first, y only as a tiebreaker). Fully
//                           covered windows sort after the visible ones, so
//                           what's on screen always owns the low numbers.
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

// r with o cut out of it, as up to 4 rects.
function subtract(r, o) {
    var x1 = Math.max(r.x, o.x), x2 = Math.min(r.x + r.width, o.x + o.width);
    var y1 = Math.max(r.y, o.y), y2 = Math.min(r.y + r.height, o.y + o.height);
    if (x1 >= x2 || y1 >= y2) return [r];
    var out = [];
    if (r.y < y1) out.push({ x: r.x, y: r.y, width: r.width, height: y1 - r.y });
    if (y2 < r.y + r.height) out.push({ x: r.x, y: y2, width: r.width, height: r.y + r.height - y2 });
    if (r.x < x1) out.push({ x: r.x, y: y1, width: x1 - r.x, height: y2 - y1 });
    if (x2 < r.x + r.width) out.push({ x: x2, y: y1, width: r.x + r.width - x2, height: y2 - y1 });
    return out;
}

// True if any sliver of w survives being covered by the windows above it.
function visible(w, above) {
    var g = w.frameGeometry;
    var rects = [{ x: g.x, y: g.y, width: g.width, height: g.height }];
    for (var i = 0; i < above.length && rects.length; i++) {
        var o = above[i].frameGeometry, next = [];
        for (var j = 0; j < rects.length; j++) {
            var parts = subtract(rects[j], o);
            for (var k = 0; k < parts.length; k++) {
                if (parts[k].width > 0 && parts[k].height > 0) next.push(parts[k]);
            }
        }
        rects = next;
    }
    return rects.length > 0;
}

// x, then y, then topmost first.
function byPosition(a, b) {
    var ga = a.w.frameGeometry, gb = b.w.frameGeometry;
    if (ga.x !== gb.x) return ga.x - gb.x;
    if (ga.y !== gb.y) return ga.y - gb.y;
    return b.stack - a.stack;
}

// Normal, focusable windows on the current desktop. stackingOrder (bottom to
// top) tells each window what covers it; visible ones take the low numbers and
// fully covered ones follow, each group sorted x then y.
function windows() {
    var stack = workspace.stackingOrder;
    var cand = [];
    for (var i = 0; i < stack.length; i++) {
        var w = stack[i];
        if (!w || !w.normalWindow || w.specialWindow) continue;
        if (w.minimized || w.hidden || w.skipSwitcher) continue;
        if (!onCurrentDesktop(w)) continue;
        cand.push(w);
    }
    var vis = [], covered = [];
    for (var n = 0; n < cand.length; n++) {
        var e = { w: cand[n], stack: n };
        (visible(cand[n], cand.slice(n + 1)) ? vis : covered).push(e);
    }
    vis.sort(byPosition);
    covered.sort(byPosition);
    var out = [];
    for (var a = 0; a < vis.length; a++) out.push(vis[a].w);
    for (var b = 0; b < covered.length; b++) out.push(covered[b].w);
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
