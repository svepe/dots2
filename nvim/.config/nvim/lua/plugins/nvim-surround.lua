-- nvim-surround — tpope/vim-surround-style surroundings with proper dot-repeat.
-- Uses its default (tpope) mappings, so nothing to configure: ys add, cs change,
-- ds delete, S in visual. e.g. ysiw" , ysw" , ds" , cs"' , ysiwf (function call).
-- Bare `s` stays flash — surround uses ys/cs/ds/S, not bare s.
vim.pack.add({ { src = "https://github.com/kylechui/nvim-surround" } })
require("nvim-surround").setup()
