-- todo-comments — highlight and search TODO/FIXME/HACK/WARN/PERF/NOTE/TEST
-- comments. Defaults are good; keymaps live centrally in config.keymaps.
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/folke/todo-comments.nvim" },
})
require("todo-comments").setup()
