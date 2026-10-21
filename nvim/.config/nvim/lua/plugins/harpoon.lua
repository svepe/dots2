-- harpoon: pin the few files a task actually needs and jump to them by slot.
-- Marks are per project and persist. Keymaps live in config.keymaps
-- (<leader>fa add, <leader>fp menu, <leader>h/j/k/l slots).
vim.pack.add({
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
})

require("harpoon"):setup()
