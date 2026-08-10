-- nvim-treesitter (main branch) — parsers drive highlighting, indent and
-- textobjects. Unlike the old master API, main installs parsers explicitly and
-- highlighting is started per-buffer via a FileType autocmd.
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

-- Parsers to keep installed (your languages + the data/config formats you use,
-- plus a few for editing this config). install() is async and skips parsers
-- already present, so it's safe to call on every startup.
local langs = {
  "bash", "c", "cpp", "lua", "python", "rust",
  "json", "yaml", "toml", "markdown", "markdown_inline", "csv",
  "vim", "vimdoc", "query", "diff", "gitcommit",
}
-- The main branch builds parsers with the tree-sitter CLI, installed by mason
-- (see plugins/lsp.lua). If it isn't on PATH yet on first launch, wait for
-- mason to finish and then install the parsers.
local function install_parsers()
  if vim.fn.executable("tree-sitter") == 0 then
    return false
  end
  require("nvim-treesitter").install(langs)
  return true
end

if not install_parsers() then
  vim.api.nvim_create_autocmd("User", {
    pattern = "MasonToolInstallerFinished",
    once = true,
    callback = function()
      vim.schedule(install_parsers)
    end,
  })
end

-- Enable treesitter highlighting (and its indent) for any buffer whose language
-- has a parser; pcall skips filetypes without one. Indent is experimental on
-- main — drop the indentexpr line if a language indents badly.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dots-treesitter", { clear = true }),
  callback = function()
    if pcall(vim.treesitter.start) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
