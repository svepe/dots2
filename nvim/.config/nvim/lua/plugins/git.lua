-- Git: gitsigns (gutter signs + inline hunk ops, feeds lualine's diff counter),
-- neogit (magit-style status/stage/commit UI), diffview (rich diff + file
-- history, and neogit's diff backend). Keymaps live in config.keymaps (<leader>g).
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/sindrets/diffview.nvim" },
  { src = "https://github.com/NeogitOrg/neogit" },
})

require("gitsigns").setup()
require("diffview").setup()
require("neogit").setup({
  integrations = { diffview = true, telescope = true },
})
