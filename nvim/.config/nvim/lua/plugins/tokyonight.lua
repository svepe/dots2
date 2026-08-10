-- tokyonight colorscheme
vim.pack.add({ { src = "https://github.com/folke/tokyonight.nvim" } })

require("tokyonight").setup({
  style = "night",
  on_highlights = function(hl, c)
    -- tokyonight's default add/change gutter colors are both teal and blend
    -- together; pin them to the palette's clear green/blue/red (theme/palette.sh).
    hl.GitSignsAdd = { fg = "#9ece6a" } -- C_GREEN
    hl.GitSignsChange = { fg = "#7aa2f7" } -- C_BLUE
    hl.GitSignsDelete = { fg = "#f7768e" } -- C_RED
  end,
})

vim.cmd.colorscheme("tokyonight")
