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

-- Show dotfiles and gitignored files (like our neo-tree), but skip .git/ guts
-- and files nvim can't usefully open. Without the blob globs a gitignored data
-- dir swamps the source tree: one ROS workspace listed 480k jpg map tiles
-- (DVC-managed) around 634 real files. Extensions, not directory names, so it
-- holds for any project.
local ignore_globs = {
  "--glob", "!**/.git/*",
  "--glob", "!**/.dvc/cache/*",
  -- images (svg stays: it's text you may want to edit)
  "--glob", "!*.{png,jpg,jpeg,gif,bmp,tif,tiff,webp,ico,xcf,psd}",
  -- audio/video
  "--glob", "!*.{mp4,mkv,mov,avi,webm,mp3,wav,flac,ogg}",
  -- archives
  "--glob", "!*.{zip,tar,gz,tgz,bz2,xz,zst,7z,rar}",
  -- compiled objects
  "--glob", "!*.{o,a,so,dylib,dll,exe,bin,obj,lib,pyc,pyo,pyd,class,jar}",
  -- datasets, model weights, dbs, ROS bags
  "--glob", "!*.{pdf,ldb,sst,db,sqlite,sqlite3,db3,bag,mcap,pcd,npy,npz,pt,pth,onnx,pkl,h5,hdf5}",
  -- fonts
  "--glob", "!*.{ttf,otf,woff,woff2}",
}

local grep_args = vim.list_extend({
  "rg", "--color=never", "--no-heading", "--with-filename",
  "--line-number", "--column", "--smart-case",
  "--hidden", "--no-ignore",
}, ignore_globs)

local find_args = vim.list_extend({
  "rg", "--files", "--hidden", "--no-ignore",
}, ignore_globs)

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
      find_command = find_args,
    },
  },
  extensions = {
    ["ui-select"] = {},
  },
})

telescope.load_extension("fzf")
telescope.load_extension("ui-select")
