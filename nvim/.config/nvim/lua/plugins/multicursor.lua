-- multicursor.nvim — Sublime-style multiple cursors, built on native extmarks.
-- Trigger keymaps (Alt-based, see config.keymaps) never touch native Vim keys;
-- the in-mode layer below is only active while cursors exist.
vim.pack.add({ { src = "https://github.com/jake-stewart/multicursor.nvim", version = "1.0" } })

local mc = require("multicursor-nvim")
mc.setup()

-- Keys active ONLY while multiple cursors exist (safe — no normal-mode impact).
mc.addKeymapLayer(function(layer)
  layer({ "n", "x" }, "<left>", mc.prevCursor) -- rotate to previous cursor
  layer({ "n", "x" }, "<right>", mc.nextCursor) -- rotate to next cursor
  layer({ "n", "x" }, "<leader>x", mc.deleteCursor) -- remove the main cursor
  layer("n", "<esc>", function()
    if mc.hasCursors() then
      mc.clearCursors()
    end
  end)
end)
