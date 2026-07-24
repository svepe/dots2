-- LSP stack. mason installs/manages tooling; nvim-lspconfig ships the server
-- configs consumed by the 0.11+ vim.lsp API; lazydev wires lua_ls for editing
-- this config. Formatting is owned by conform (see plugins/conform.lua), so
-- nothing here touches it — no documentFormattingProvider juggling.
vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/folke/lazydev.nvim" },
})

require("mason").setup()

-- Servers mason should install. System/toolchain servers (clangd, rust_analyzer,
-- ruff) are intentionally absent — they live on PATH and we manage them.
require("mason-lspconfig").setup({
  ensure_installed = { "pyright", "lua_ls", "jsonls", "yamlls" },
  automatic_enable = false, -- we enable everything explicitly below
})

-- Non-LSP tools (conform formatters) that mason should keep installed.
require("mason-tool-installer").setup({
  ensure_installed = { "stylua", "prettier" },
})

require("lazydev").setup()

-- Diagnostics presentation.
vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = true },
  virtual_text = true,
  signs = true,
})

-- Enable all servers: mason-managed + system/toolchain (on PATH).
vim.lsp.enable({ "clangd", "rust_analyzer", "ruff", "pyright", "lua_ls", "jsonls", "yamlls" })

-- Diagnostics keymaps (global — no server needed), <leader>m scheme.
vim.keymap.set("n", "<leader>me", vim.diagnostic.open_float, { desc = "Explain error (float)" })
vim.keymap.set("n", "<leader>mp", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "<leader>mn", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

-- Buffer-local keymaps + per-server tweaks, set when a server attaches. These
-- sit alongside nvim's built-in defaults (K, grn, gra, grr, gri, grt, gO, [d/]d).
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("dots-lsp-attach", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    -- pyright owns hover/types; ruff owns lint + code actions (no dup hovers)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    local map = function(keys, fn, desc, modes)
      vim.keymap.set(modes or "n", keys, fn, { buffer = buf, desc = desc })
    end
    map("<leader>md", vim.lsp.buf.definition, "Definition")
    map("<leader>mD", vim.lsp.buf.declaration, "Declaration")
    map("<leader>mT", vim.lsp.buf.type_definition, "Type definition")
    map("<leader>mr", vim.lsp.buf.references, "References")
    map("<leader>mR", vim.lsp.buf.rename, "Rename")
    map("<leader>ms", vim.lsp.buf.signature_help, "Signature help")
    map("<leader>ma", vim.lsp.buf.code_action, "Code action", { "n", "v" })
    map("<leader>mwa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
    map("<leader>mwr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
  end,
})
