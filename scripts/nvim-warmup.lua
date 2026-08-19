-- Headless warm-up for the nvim config: pre-install everything that would
-- otherwise be pulled on the first interactive launch, so a freshly-provisioned
-- machine is ready offline. Invoked by scripts/22-nvim.sh as:
--
--   nvim --headless -c 'luafile <this>' -c 'qa!'
--
-- By the time this runs the user config has already loaded, so vim.pack has
-- installed the plugins (synchronous) and mason + treesitter have kicked off
-- their async installs. All we do here is WAIT for those to drain, with bounded
-- timeouts — anything still pending just finishes on the first real launch.

local function log(m) io.stderr:write("  [nvim-warmup] " .. m .. "\n") end

-- 1. mason: wait for the tool-installer to finish (stylua, prettier,
--    tree-sitter-cli) AND for the installed-package count to stop growing (this
--    also covers the LSP servers mason-lspconfig pulls: basedpyright, lua_ls,
--    jsonls, yamlls). Fall back to a longer no-activity window in case the
--    MasonToolInstallerFinished event doesn't fire (e.g. nothing to install).
local tool_done = false
vim.api.nvim_create_autocmd("User", {
  pattern = "MasonToolInstallerFinished",
  once = true,
  callback = function() tool_done = true end,
})
local last, stable = -1, 0
vim.wait(300000, function()
  local ok, reg = pcall(require, "mason-registry")
  local n = ok and #reg.get_installed_packages() or 0
  if n == last then stable = stable + 1 else stable, last = 0, n end
  return (tool_done and stable >= 20) or stable >= 60 -- 10s after done, or 30s idle
end, 500)
log("mason settled with " .. last .. " package(s)")

-- 2. treesitter (main branch): install() is async and skips parsers already
--    built (silently — install.lua returns early with no echo). Pre-installing
--    every parser HERE is what keeps the config's startup install() quiet on the
--    first interactive launch — otherwise it echoes progress and forces repeated
--    "Press ENTER" prompts. install() gives no waitable handle, so trigger it and
--    poll get_installed("parsers") until they're all present. Needs the
--    tree-sitter CLI, installed by mason in step 1.
if vim.fn.executable("tree-sitter") == 1 then
  local ok, nts = pcall(require, "nvim-treesitter")
  if ok then
    local langs = {
      "bash", "c", "cpp", "lua", "python", "rust",
      "json", "yaml", "toml", "markdown", "markdown_inline", "csv",
      "vim", "vimdoc", "query", "diff", "gitcommit",
    }
    local function missing()
      local have = {}
      for _, p in ipairs(nts.get_installed("parsers")) do
        have[p] = true
      end
      local m = {}
      for _, l in ipairs(langs) do
        if not have[l] then
          m[#m + 1] = l
        end
      end
      return m
    end
    pcall(function() nts.install(langs) end) -- idempotent; skips built parsers
    if vim.wait(300000, function() return #missing() == 0 end, 1000) then
      log("treesitter: all " .. #langs .. " parsers installed")
    else
      log("treesitter: timed out, still missing: " .. table.concat(missing(), ", "))
    end
  end
else
  log("tree-sitter CLI not on PATH yet — parsers build on first launch")
end
