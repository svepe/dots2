-- blink.cmp — completion popup that appears as you type. Batteries-included:
-- LSP, path, buffer and snippet sources with sensible defaults, plus a fast
-- prebuilt fuzzy matcher (fetched for the pinned release). It injects its
-- completion capabilities into all LSP servers automatically (vim.lsp.config).
-- Keymaps mirror the old nvim-cmp setup: C-j/C-k select, CR/Tab accept.
vim.pack.add({
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
})

require("blink.cmp").setup({
  keymap = {
    preset = "none",
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
    ["<C-e>"] = { "hide", "fallback" },
    ["<C-j>"] = { "select_next", "fallback" }, -- hjkl-style navigation
    ["<C-k>"] = { "select_prev", "fallback" },
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    ["<CR>"] = { "accept", "fallback" }, -- Enter accepts
    ["<Tab>"] = { "accept", "fallback" }, -- Tab also accepts
  },
  completion = {
    -- first item preselected so Enter/Tab accept it without navigating first
    list = { selection = { preselect = true, auto_insert = false } },
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },
  signature = { enabled = true }, -- signature help while typing args
})
