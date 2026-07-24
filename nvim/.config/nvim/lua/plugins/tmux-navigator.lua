-- Seamless navigation between nvim splits and tmux panes with C-h/j/k/l.
-- tmux side is handled by the christoomey/vim-tmux-navigator tpm plugin (see
-- tmux/.config/tmux/tmux.conf). The plugin maps <C-h/j/k/l> (and <C-\> for the
-- previous split/pane) on its own, so there are no keymaps to define here.
vim.pack.add({ { src = "https://github.com/christoomey/vim-tmux-navigator" } })
