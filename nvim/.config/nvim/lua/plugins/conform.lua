-- conform.nvim — formatting via CLI formatters. Runs on save and on <leader>mf
-- (keymap in config.keymaps). Formatter binaries come from PATH: stylua/prettier
-- via mason; clang-format/ruff/rustfmt system-managed.
vim.pack.add({ { src = "https://github.com/stevearc/conform.nvim" } })

require("conform").setup({
  formatters_by_ft = {
    python = { "ruff_organize_imports", "ruff_format" }, -- imports then code
    lua = { "stylua" },
    c = { "clang_format" },
    cpp = { "clang_format" },
    rust = { "rustfmt" },
    json = { "prettier" },
    jsonc = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
  },
  -- format on write; fall back to LSP formatting when no CLI formatter is set
  format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
})
