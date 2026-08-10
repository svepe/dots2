-- telescope — fuzzy finder. fzf-native gives fast native sorting but needs a
-- compile step; the PackChanged hook builds it on install/update. ui-select
-- routes vim.ui.select (e.g. LSP code actions) through telescope. Keymaps live
-- in config.keymaps. Requires ripgrep (rg) for find_files and grep.

-- Build fzf-native's C sorter after vim.pack installs/updates it. Registered
-- before add() so it fires during the synchronous install.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local d = ev.data
    if d.spec and d.spec.name == "telescope-fzf-native.nvim" and d.kind ~= "delete" then
      vim.system({ "make" }, { cwd = d.path }):wait()
    end
  end,
})

vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
})

-- Show dotfiles and gitignored files (like our neo-tree), but skip .git/ guts.
local grep_args = {
  "rg", "--color=never", "--no-heading", "--with-filename",
  "--line-number", "--column", "--smart-case",
  "--hidden", "--no-ignore", "--glob", "!**/.git/*",
}

local telescope = require("telescope")
telescope.setup({
  defaults = {
    vimgrep_arguments = grep_args,
    mappings = {
      i = { -- hjkl-style result navigation (see [[vim-style-keybindings]])
        ["<C-j>"] = "move_selection_next",
        ["<C-k>"] = "move_selection_previous",
      },
    },
  },
  pickers = {
    find_files = {
      find_command = { "rg", "--files", "--hidden", "--no-ignore", "--glob", "!**/.git/*" },
    },
  },
  extensions = {
    ["ui-select"] = {},
  },
})

telescope.load_extension("fzf")
telescope.load_extension("ui-select")
