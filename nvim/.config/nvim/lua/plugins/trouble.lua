-- trouble — a docked panel for diagnostics, symbols, references, quickfix, etc.
-- Live-updates as diagnostics change. Keymaps live centrally in config.keymaps
-- (<leader>mt subgroup). Defaults are good on v3.
vim.pack.add({ { src = "https://github.com/folke/trouble.nvim" } })
require("trouble").setup({})
