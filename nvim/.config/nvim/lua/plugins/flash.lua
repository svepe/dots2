-- flash — jump anywhere on screen with `s` (see config.keymaps). Char mode is
-- disabled so f/t/F/T stay 100% native; `s` is the only flash key.
vim.pack.add({ { src = "https://github.com/folke/flash.nvim" } })
require("flash").setup({
  highlight = { backdrop = true },
  prompt = { enabled = false },
  jump = { autojump = true }, -- jump immediately when there's a single match
  modes = {
    char = { enabled = false },
  },
})
