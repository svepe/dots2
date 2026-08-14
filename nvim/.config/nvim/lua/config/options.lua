-- Editor options — one concise comment per line. Settings from the old config
-- are carried over; the rest are sensible modern defaults.
local o = vim.opt

-- indentation — 4-space, expand tabs
o.tabstop = 4           -- a TAB renders as 4 columns
o.softtabstop = 4       -- <Tab>/<BS> act on 4 spaces
o.shiftwidth = 4        -- indent step is 4 spaces
o.expandtab = true      -- insert spaces, never literal tabs
o.breakindent = true    -- wrapped lines keep their indentation

-- line numbers
o.number = true         -- absolute number on the current line
o.relativenumber = true -- relative numbers on the other lines

-- splits
o.splitright = true     -- vertical splits open to the right
o.splitbelow = true     -- horizontal splits open below

-- search
o.ignorecase = true     -- case-insensitive search...
o.smartcase = true      -- ...unless the query contains a capital
o.inccommand = "split"  -- live-preview :substitute results

-- clipboard & files
o.clipboard = "unnamedplus" -- share the system clipboard (needs wl-clipboard)
o.undofile = true       -- persist undo history across sessions

-- ui
o.termguicolors = true  -- 24-bit color
o.showmode = false      -- mode is shown in the statusline instead
o.signcolumn = "yes"    -- always show the sign column (avoids text shifting)
o.cursorline = true     -- highlight the current line
o.scrolloff = 10        -- keep 10 lines above/below the cursor
o.list = true           -- render whitespace...
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" } -- ...as these glyphs
o.winborder = "rounded" -- rounded border on floats (hover, signature, docs)

-- behaviour
o.updatetime = 250      -- faster CursorHold / swap writes (ms)
o.timeoutlen = 300      -- mapping-sequence timeout (ms)
o.confirm = true        -- prompt to save rather than failing :q

-- briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("dots-yank-highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})
