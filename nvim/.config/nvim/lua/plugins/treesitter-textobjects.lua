-- treesitter-textobjects (main) — adds the objects Vim lacks: function, class,
-- argument. Native objects (i", iw, i(, ...) are deliberately NOT remapped, so
-- ci"/ciw and their dot-repeat keep working. Keymaps live in config.keymaps.
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
})
require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true }, -- jump forward to the textobject (targets.vim-like)
})
