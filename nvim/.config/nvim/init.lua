-- dots2 Neovim config. Plugin management via the built-in vim.pack (nvim 0.12+).
-- Leader must be set before any plugin loads.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("plugins")
