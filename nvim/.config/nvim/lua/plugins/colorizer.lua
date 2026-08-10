-- nvim-colorizer — render color codes inline in their actual color. Handy for
-- eyeballing data-viz palettes. Auto-attaches to buffers; :ColorizerToggle to
-- flip it off.
vim.pack.add({ { src = "https://github.com/NvChad/nvim-colorizer.lua" } })
require("colorizer").setup({
  user_default_options = {
    RGB = true, -- #RGB hex
    RRGGBB = true, -- #RRGGBB hex
    names = false, -- don't colorize bare words like "blue"
    RRGGBBAA = false, -- #RRGGBBAA hex
    AARRGGBB = false, -- 0xAARRGGBB hex
    css = true, -- rgb()/hsl() functions plus RGB/RRGGBB
  },
})
