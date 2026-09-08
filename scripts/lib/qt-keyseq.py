#!/usr/bin/env python3
"""Encode KDE key sequences as the integers kglobalaccel's D-Bus API expects.

kglobalaccel takes shortcuts as `a(ai)`: a list of QKeySequences, each a
zero-padded array of four ints, where an int is `Qt::Key | modifier bits`.
Config files instead spell shortcuts as text ("Meta+Alt+H"), so applying a
shortcut to the *running* daemon means translating between the two.

Takes one argument: the alternatives for a single action, separated by ";"
(the config file separates them with a tab). "none" or "" means "unbound",
which the D-Bus API spells as an empty list. Prints a busctl argument
fragment for the `a(ai)` value, and exits non-zero on an unknown key name
rather than silently binding the wrong key.

    $ qt-keyseq.py 'Ctrl+Alt+O;Screensaver'
    2 4 201326671 0 0 0 4 16777402 0 0 0
"""

import sys

# Qt::KeyboardModifier
MODIFIERS = {
    "shift": 0x02000000,
    "ctrl": 0x04000000,
    "control": 0x04000000,
    "alt": 0x08000000,
    "meta": 0x10000000,
    "super": 0x10000000,
}

# Qt::Key — the named keys this repo's shortcuts actually use. Letters, digits
# and F-keys are computed below; anything missing is an error, not a guess.
KEYS = {
    "left": 0x01000012, "up": 0x01000013,
    "right": 0x01000014, "down": 0x01000015,
    "return": 0x01000004, "enter": 0x01000005,
    "pgup": 0x01000016, "pageup": 0x01000016, "prior": 0x01000016,
    "pgdown": 0x01000017, "pagedown": 0x01000017, "next": 0x01000017,
    "home": 0x01000010, "end": 0x01000011,
    "esc": 0x01000000, "escape": 0x01000000,
    "tab": 0x01000001, "backtab": 0x01000002,
    "backspace": 0x01000003, "space": 0x20,
    "ins": 0x01000006, "insert": 0x01000006,
    "del": 0x01000007, "delete": 0x01000007,
    "print": 0x01000009, "menu": 0x01000055,
    "screensaver": 0x010000BA,
}
KEYS.update({chr(c): c for c in range(ord("a"), ord("z") + 1)})   # Qt::Key_A..Z
KEYS.update({chr(c): c - 0x20 for c in range(ord("a"), ord("z") + 1)})
KEYS.update({str(d): 0x30 + d for d in range(10)})                # Qt::Key_0..9
KEYS.update({f"f{n}": 0x01000030 + (n - 1) for n in range(1, 36)})  # Qt::Key_F1..


def encode(sequence):
    """"Meta+Alt+H" -> the single int QKeySequence packs it into."""
    value = 0
    parts = sequence.split("+")
    # A trailing "+" means the key itself is "+", e.g. "Meta++".
    if parts[-1] == "":
        parts = parts[:-1]
        parts[-1] = "+"
    for part in parts[:-1]:
        modifier = MODIFIERS.get(part.strip().lower())
        if modifier is None:
            sys.exit(f"qt-keyseq: unknown modifier {part!r} in {sequence!r}")
        value |= modifier
    key = KEYS.get(parts[-1].strip().lower())
    if key is None:
        sys.exit(f"qt-keyseq: unknown key {parts[-1]!r} in {sequence!r}")
    return value | key


# Canonical spelling per key code, for turning daemon replies back into names.
NAMES = {v: k for k, v in [
    ("Left", 0x01000012), ("Up", 0x01000013),
    ("Right", 0x01000014), ("Down", 0x01000015),
    ("Return", 0x01000004), ("Enter", 0x01000005),
    ("PgUp", 0x01000016), ("PgDown", 0x01000017),
    ("Home", 0x01000010), ("End", 0x01000011),
    ("Esc", 0x01000000), ("Tab", 0x01000001), ("Backtab", 0x01000002),
    ("Backspace", 0x01000003), ("Space", 0x20),
    ("Ins", 0x01000006), ("Del", 0x01000007),
    ("Print", 0x01000009), ("Menu", 0x01000055),
    ("Screensaver", 0x010000BA),
]}
NAMES.update({c: chr(c) for c in range(ord("A"), ord("Z") + 1)})
NAMES.update({0x30 + d: str(d) for d in range(10)})
NAMES.update({0x01000030 + (n - 1): f"F{n}" for n in range(1, 36)})


def decode_key(value):
    """The inverse of encode(), for readable failure messages."""
    names = []
    for name, bit in (("Meta", 0x10000000), ("Ctrl", 0x04000000),
                      ("Alt", 0x08000000), ("Shift", 0x02000000)):
        if value & bit:
            names.append(name)
            value &= ~bit
    names.append(NAMES.get(value, f"0x{value:08x}"))
    return "+".join(names)


def decode(raw):
    """Turn a busctl `a(ai)` reply back into "Meta+L;Screensaver"."""
    tokens = raw.split()
    if not tokens:
        return "none"
    count, i, sequences = int(tokens[0]), 1, []
    for _ in range(count):
        length = int(tokens[i]); i += 1
        keys = [int(t) for t in tokens[i:i + length]]; i += length
        sequences.append("+".join(decode_key(k) for k in keys if k) or "none")
    return ";".join(sequences) or "none"


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--decode":
        try:
            print(decode(sys.argv[2]))
        except (ValueError, IndexError):
            print(sys.argv[2])
        return
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    raw = sys.argv[1].strip()
    if raw.lower() in ("", "none"):
        sequences = []
    else:
        sequences = [s for s in raw.replace("\t", ";").split(";") if s.strip()]
    # Each QKeySequence marshals as four ints; we only ever use single-step
    # shortcuts, so the remaining three slots stay empty.
    out = [str(len(sequences))]
    for sequence in sequences:
        out += ["4", str(encode(sequence)), "0", "0", "0"]
    print(" ".join(out))


if __name__ == "__main__":
    main()
