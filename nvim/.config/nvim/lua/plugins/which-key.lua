-- which-key — popup listing available keybindings after a prefix (shows after
-- 'timeoutlen'). Picks up icons from nvim-web-devicons automatically. Reads the
-- `desc` on each keymap; here we just label the <leader> groups.
vim.pack.add({ { src = "https://github.com/folke/which-key.nvim" } })

local wk = require("which-key")
wk.setup({})
wk.add({
  { "<leader>f", group = "file" },
  { "<leader>b", group = "buffer" },
  { "<leader>g", group = "git" },
  { "<leader>n", group = "notes" },
  { "<leader>q", group = "quickfix" },
  { "<leader>w", group = "window" },
  { "<leader>m", group = "code" },
  { "<leader>mt", group = "trouble" },
  { "<leader>mw", group = "workspace" },
})
