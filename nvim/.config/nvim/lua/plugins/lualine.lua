-- lualine statusline
vim.pack.add({
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
})

-- show the window number in inactive statuslines (pairs with <leader>1..9)
local function window_number()
  return tostring(vim.api.nvim_win_get_number(0))
end

require("lualine").setup({
  options = {
    theme = "auto",       -- follow the active colorscheme (tokyonight)
    globalstatus = false, -- one statusline per window (old behaviour)
    -- component/section separators left at lualine's powerline defaults
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { "filename" },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  inactive_sections = {
    lualine_a = { window_number },
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
})
