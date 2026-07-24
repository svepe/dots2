-- General keymaps (plugin-free). Plugin/LSP/DAP maps live with each plugin,
-- added as those plugins land.

-- clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- save
vim.keymap.set({ "n", "v" }, "<leader>fs", "<cmd>w<cr>", { desc = "Save file" })

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
