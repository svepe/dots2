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
  -- basedpyright = pyright fork that also bundles docstrings for stdlib builtins
  -- (so hover shows prose, not just the signature).
  ensure_installed = { "basedpyright", "lua_ls", "jsonls", "yamlls" },
  automatic_enable = false, -- we enable everything explicitly below
})

-- basedpyright defaults to its stricter "recommended" diagnostics; pin to
-- "standard" (pyright's default) so we get docstrings without a flood of
-- extra warnings.
vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = { typeCheckingMode = "standard" },
    },
  },
})

-- Non-LSP tools mason should keep installed: conform formatters plus the
-- tree-sitter CLI (required by nvim-treesitter's main branch to build parsers).
require("mason-tool-installer").setup({
  ensure_installed = { "stylua", "prettier", "tree-sitter-cli" },
})

require("lazydev").setup()

-- Diagnostics presentation.
vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = true },
  virtual_text = true,
  signs = true,
})

-- Let Esc (not just q) close LSP hover/signature floats. Wrapping the single
-- function that builds them keeps this scoped to LSP previews — no editor-wide
-- float handling to babysit.
local open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  local bufnr, winid = open_floating_preview(contents, syntax, opts, ...)
  vim.keymap.set("n", "<Esc>", "<C-w>c", { buffer = bufnr, nowait = true })
  return bufnr, winid
end

-- Enable all servers: mason-managed + system/toolchain (on PATH).
vim.lsp.enable({ "clangd", "rust_analyzer", "ruff", "basedpyright", "lua_ls", "jsonls", "yamlls" })

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
    -- telescope.builtin picker by name (lazy-required — loads before this fires)
    local tb = function(name)
      return function()
        require("telescope.builtin")[name]()
      end
    end
    -- navigation (telescope pickers)
    map("<leader>md", tb("lsp_definitions"), "Definition")
    map("<leader>mD", vim.lsp.buf.declaration, "Declaration")
    map("<leader>mI", tb("lsp_implementations"), "Implementations")
    map("<leader>mT", tb("lsp_type_definitions"), "Type definition")
    map("<leader>mr", tb("lsp_references"), "References")
    map("<leader>ms", tb("lsp_document_symbols"), "Document symbols")
    map("<leader>ml", tb("diagnostics"), "List diagnostics")
    -- actions
    map("<leader>mR", vim.lsp.buf.rename, "Rename")
    map("<leader>ma", vim.lsp.buf.code_action, "Code action", { "n", "v" })
    map("<leader>mk", vim.lsp.buf.signature_help, "Signature help")
    -- workspace
    map("<leader>mws", tb("lsp_dynamic_workspace_symbols"), "Workspace symbols")
    map("<leader>mwa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
    map("<leader>mwr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
    map("<leader>mwl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "List workspace folders")

    -- inlay hints: inferred types/param names inline. On by default where the
    -- server supports them; toggle per buffer with <leader>mh.
    if client and client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = buf })
      map("<leader>mh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
      end, "Toggle inlay hints")
    end

    -- highlight other references of the symbol under the cursor (on CursorHold);
    -- cleared when the cursor moves or the server detaches.
    if client and client:supports_method("textDocument/documentHighlight") then
      local group = vim.api.nvim_create_augroup("dots-lsp-references", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

-- Clear reference highlights and their autocmds when a server detaches.
vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("dots-lsp-detach", { clear = true }),
  callback = function(ev)
    vim.lsp.buf.clear_references()
    pcall(vim.api.nvim_clear_autocmds, { group = "dots-lsp-references", buffer = ev.buf })
  end,
})
