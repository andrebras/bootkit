-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Conceal is designed to "clean up" the visual display of certain characters
-- or syntax elements by hiding or simplifying them, making text appear more
-- readable in certain contexts (like LaTeX, Markdown, JSON, etc.)
vim.opt.conceallevel = 0

-- Shows relative line numbers instead of absolute
vim.opt.relativenumber = true

-- Makes code folding work based on indentation levels
-- vim.opt.foldlevelstart = 6
vim.opt.foldmethod = "indent"

-- Ensures consistent tab width in insert mode
vim.opt.softtabstop = 2

-- Display invisible characters for clarity in whitespace
vim.opt.list = true
vim.opt.listchars = {
  tab = "»\\",
  extends = "›",
  precedes = "‹",
  nbsp = "·",
  trail = "·",
}
