-- fidget — unobtrusive corner notifications for LSP progress (e.g. rust-analyzer
-- / clangd indexing), so long-running servers show what they're doing.
vim.pack.add({ { src = "https://github.com/j-hui/fidget.nvim" } })
require("fidget").setup()
