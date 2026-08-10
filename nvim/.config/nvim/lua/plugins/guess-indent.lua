-- guess-indent — detect and set indentation (shiftwidth/expandtab/tabstop) from
-- file content. Defers to .editorconfig and modelines (both handled natively by
-- Neovim). A faster, Lua replacement for vim-sleuth.
vim.pack.add({ { src = "https://github.com/nmac427/guess-indent.nvim" } })
require("guess-indent").setup()
