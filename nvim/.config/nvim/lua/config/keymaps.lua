-- Central keymaps. Plugin maps live here too (lazy-require the plugin inside the
-- callback, since this file loads before plugins/). Per-buffer LSP maps are the
-- exception — they attach in plugins/lsp.lua.

-- clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- markdown preview: buffer-local in markdown files (its command is buffer-local
-- too). which-key auto-shows it under <leader>m when editing markdown.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", {
      buffer = ev.buf,
      desc = "Markdown preview",
    })
  end,
})

-- flash: jump anywhere with `s` (replaces native substitute; use cl for that)
vim.keymap.set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash jump" })

-- multiple cursors (multicursor.nvim), Alt-based so no native Vim key is
-- overridden; Alt+D echoes Sublime's Cmd+D. In-cursor-mode layer lives in
-- plugins/multicursor.lua. Verified free of keyd/KDE/tmux/alacritty grabs.
local function mc(method, arg)
  return function()
    local m = require("multicursor-nvim")
    if arg == nil then
      m[method]()
    else
      m[method](arg)
    end
  end
end
vim.keymap.set({ "n", "x" }, "<M-d>", mc("matchAddCursor", 1), { desc = "Cursor: add next match" })
vim.keymap.set({ "n", "x" }, "<M-p>", mc("matchAddCursor", -1), { desc = "Cursor: add previous match" })
vim.keymap.set({ "n", "x" }, "<M-x>", mc("matchSkipCursor", 1), { desc = "Cursor: skip match" })
vim.keymap.set({ "n", "x" }, "<M-j>", mc("lineAddCursor", 1), { desc = "Cursor: add below" })
vim.keymap.set({ "n", "x" }, "<M-k>", mc("lineAddCursor", -1), { desc = "Cursor: add above" })
vim.keymap.set({ "n", "x" }, "<M-a>", mc("matchAllAddCursors"), { desc = "Cursor: add all matches" })

-- discoverable <leader>c mirror (which-key shows these with their M- chord); the
-- Alt chords above stay for fast use.
vim.keymap.set({ "n", "x" }, "<leader>cd", mc("matchAddCursor", 1), { desc = "Add next match (M-d)" })
vim.keymap.set({ "n", "x" }, "<leader>cp", mc("matchAddCursor", -1), { desc = "Add previous match (M-p)" })
vim.keymap.set({ "n", "x" }, "<leader>cx", mc("matchSkipCursor", 1), { desc = "Skip match (M-x)" })
vim.keymap.set({ "n", "x" }, "<leader>cj", mc("lineAddCursor", 1), { desc = "Add below (M-j)" })
vim.keymap.set({ "n", "x" }, "<leader>ck", mc("lineAddCursor", -1), { desc = "Add above (M-k)" })
vim.keymap.set({ "n", "x" }, "<leader>ca", mc("matchAllAddCursors"), { desc = "Add all matches (M-a)" })

-- save
vim.keymap.set({ "n", "v" }, "<leader>fs", "<cmd>w<cr>", { desc = "Save file" })

-- find (telescope)
vim.keymap.set("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fd", function()
  require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Find files (current dir)" })
vim.keymap.set("n", "<leader>fr", function()
  require("telescope.builtin").oldfiles()
end, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fh", function()
  require("telescope.builtin").help_tags()
end, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fk", function()
  require("telescope.builtin").keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>bb", function()
  require("telescope.builtin").buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>:", function()
  require("telescope.builtin").command_history()
end, { desc = "Command history" })

-- grep (telescope): / types a pattern, * greps word/selection — mirrors vim's
-- own / and * one level up (buffer -> project).
vim.keymap.set("n", "<leader>/", function()
  require("telescope.builtin").live_grep()
end, { desc = "Grep project" })
vim.keymap.set("n", "<leader>*", function()
  require("telescope.builtin").grep_string()
end, { desc = "Grep word under cursor" })
vim.keymap.set("v", "<leader>*", function()
  local save = vim.fn.getreg("v")
  vim.cmd('noautocmd normal! "vy')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", save)
  require("telescope.builtin").grep_string({ search = text })
end, { desc = "Grep selection" })

-- buffers: bnext/bprevious cycle only listed buffers (closed ones are already
-- off the list, neo-tree's unlisted buffer is skipped); pcall guards the
-- single-buffer no-op so it never errors.
vim.keymap.set("n", "<leader>bn", function()
  pcall(vim.cmd.bnext)
end, { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", function()
  pcall(vim.cmd.bprevious)
end, { desc = "Previous buffer" })

-- scratch: a throwaway [scratch] buffer, reused via a kept handle (created
-- listed + scratch, so it stays hidden rather than being wiped).
local scratch_bufnr
vim.keymap.set("n", "<leader>bs", function()
  if scratch_bufnr and vim.api.nvim_buf_is_valid(scratch_bufnr) then
    vim.api.nvim_set_current_buf(scratch_bufnr)
    return
  end
  scratch_bufnr = vim.api.nvim_create_buf(true, true)
  pcall(vim.api.nvim_buf_set_name, scratch_bufnr, "[scratch]")
  vim.api.nvim_set_current_buf(scratch_bufnr)
end, { desc = "Scratch buffer" })

-- delete current buffer without closing its window/split (mini.bufremove);
-- force=false so it prompts on unsaved changes.
vim.keymap.set("n", "<leader>bd", function()
  require("mini.bufremove").delete(0, false)
end, { desc = "Delete buffer" })

-- registers & marks: previewed, fuzzy lists — mirror vim's " and ' prefixes.
vim.keymap.set("n", '<leader>"', function()
  require("telescope.builtin").registers()
end, { desc = "Registers" })
vim.keymap.set("n", "<leader>'", function()
  require("telescope.builtin").marks()
end, { desc = "Marks" })

-- treesitter textobjects: function/class/argument. Native objects (i"/iw/...)
-- are intentionally not remapped, so ci"/ciw dot-repeat stays intact.
local function ts_select(obj)
  return function()
    require("nvim-treesitter-textobjects.select").select_textobject(obj, "textobjects")
  end
end
vim.keymap.set({ "x", "o" }, "af", ts_select("@function.outer"), { desc = "a function" })
vim.keymap.set({ "x", "o" }, "if", ts_select("@function.inner"), { desc = "inner function" })
vim.keymap.set({ "x", "o" }, "ac", ts_select("@class.outer"), { desc = "a class" })
vim.keymap.set({ "x", "o" }, "ic", ts_select("@class.inner"), { desc = "inner class" })
vim.keymap.set({ "x", "o" }, "aa", ts_select("@parameter.outer"), { desc = "an argument" })
vim.keymap.set({ "x", "o" }, "ia", ts_select("@parameter.inner"), { desc = "inner argument" })

-- todo comments (<leader>n): find and step through TODO/FIXME/etc.
vim.keymap.set("n", "<leader>ns", "<cmd>TodoTelescope<cr>", { desc = "Search todos" })
vim.keymap.set("n", "<leader>nq", "<cmd>TodoQuickFix<cr>", { desc = "Todos to quickfix" })
vim.keymap.set("n", "<leader>nn", function()
  require("todo-comments").jump_next()
end, { desc = "Next todo" })
vim.keymap.set("n", "<leader>np", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous todo" })

-- git (<leader>g): neogit for status/staging/commit; gitsigns for hunk nav.
vim.keymap.set({ "n", "v" }, "<leader>gs", function()
  require("neogit").open({ kind = "vsplit" })
end, { desc = "Status (neogit)" })
vim.keymap.set("n", "<leader>gn", function()
  require("gitsigns").nav_hunk("next")
end, { desc = "Next hunk" })
vim.keymap.set("n", "<leader>gp", function()
  require("gitsigns").nav_hunk("prev")
end, { desc = "Previous hunk" })

-- quickfix (<leader>q): populate the list from any telescope picker with <C-q>,
-- then step through entries here. qn/qp wrap at the ends.
local function qf_step(step, wrap)
  return function()
    if not pcall(vim.cmd, step) then
      pcall(vim.cmd, wrap)
    end
  end
end
vim.keymap.set("n", "<leader>qn", qf_step("cnext", "cfirst"), { desc = "Next item" })
vim.keymap.set("n", "<leader>qp", qf_step("cprevious", "clast"), { desc = "Previous item" })
vim.keymap.set("n", "<leader>qo", "<cmd>copen<cr>", { desc = "Open list" })
vim.keymap.set("n", "<leader>qd", "<cmd>cclose<cr>", { desc = "Close list" })
vim.keymap.set("n", "<leader>qx", "<cmd>cexpr []<cr>", { desc = "Clear list" })

-- format (conform, falls back to LSP)
vim.keymap.set({ "n", "v" }, "<leader>mf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format file" })

-- trouble panel (<leader>mt): docked views of diagnostics/symbols/lists.
vim.keymap.set("n", "<leader>mtd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Document diagnostics" })
vim.keymap.set("n", "<leader>mtw", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Workspace diagnostics" })
vim.keymap.set("n", "<leader>mts", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols outline" })
vim.keymap.set("n", "<leader>mtr", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/defs" })
vim.keymap.set("n", "<leader>mtq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix" })
vim.keymap.set("n", "<leader>mtl", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
vim.keymap.set("n", "<leader>mtt", "<cmd>Trouble todo toggle<cr>", { desc = "Todos" })

-- file tree
vim.keymap.set("n", "<leader>ft", "<cmd>Neotree filesystem reveal left<cr>", { desc = "File tree" })

-- windows
vim.keymap.set("n", "<leader>wd", "<C-w>c", { desc = "Close window" })
vim.keymap.set("n", "<leader>ws", "<C-w>s", { desc = "Split below" })
vim.keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split right" })
-- jump to window N
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. i, i .. "<C-w>w", { desc = "which_key_ignore" })
end
