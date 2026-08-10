-- mini.nvim modules, installed individually. Grows as we adopt more.
-- Keymaps live centrally in config.keymaps.

-- mini.bufremove — delete a buffer while keeping the window layout intact.
vim.pack.add({ { src = "https://github.com/echasnovski/mini.bufremove" } })
require("mini.bufremove").setup()
