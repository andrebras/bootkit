-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- General
vim.opt.guifont = "CaskaydiaCove Nerd Font Mono"
vim.opt.foldmethod = "indent"
vim.opt.foldlevelstart = 6
vim.opt.relativenumber = true

lvim.log.level = "info"
lvim.format_on_save.enabled = false

-- Colorscheme
lvim.colorscheme = "tokyonight-day"

-- User config for builtin plugins
lvim.builtin.alpha.active       = true
lvim.builtin.breadcrumbs.active = false
lvim.builtin.dap.active         = false
lvim.builtin.indentlines.active = true
lvim.builtin.lir.active         = true
lvim.builtin.lualine.active     = true
lvim.builtin.nvimtree.active    = true
lvim.builtin.project.active     = true
lvim.builtin.terminal.active    = true

-- Terminal
lvim.builtin.terminal.direction = 'horizontal'

-- Bufferline
lvim.builtin.bufferline.options.color_icons = true
lvim.builtin.bufferline.options.show_tab_indicators = false

-- Nvimtree
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.view.width = 40
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.nvimtree.setup.renderer.icons.webdev_colors = true

-- Lir
lvim.builtin.lir.show_hidden_files = true
lvim.builtin.lir.ignore = {
  ".DS_Store",
  ".bundle",
  ".git",
  ".idea",
  "node_modules"
}

-- Keymappings
lvim.keys.visual_mode["ga"] = "<Plug>(EasyAlign)"
lvim.keys.normal_mode["ga"] = "<Plug>(EasyAlign)"

lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"

-- Language parsers
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "css",
  "elixir",
  "javascript",
  "json",
  "lua",
  "python",
  "ruby",
  "rust",
  "toml",
  "tsx",
  "typescript",
  "vimdoc",
  "yaml",
}

-- Telescope
-- Change Telescope navigation to use j and k for navigation and n and p for
-- history in both input and normal mode. We use protected-mode (pcall) just
-- in case the plugin wasn't loaded yet.
local _, actions = pcall(require, "telescope.actions")

lvim.builtin.telescope.defaults.mappings = {
  -- for input mode
  i = {
    ["<C-j>"] = actions.move_selection_next,
    ["<C-k>"] = actions.move_selection_previous,
    ["<C-n>"] = actions.cycle_history_next,
    ["<C-p>"] = actions.cycle_history_prev,
  },
  -- for normal mode
  n = {
    ["<C-j>"] = actions.move_selection_next,
    ["<C-k>"] = actions.move_selection_previous,
  },
}

lvim.builtin.telescope = {
  defaults = { },
  pickers = {
    buffers   = { theme = "dropdown" },
    git_files = { theme = "dropdown" },
    live_grep = { theme = "ivy" },
  },
}

-- Language Servers
-- Disable automatic installation
lvim.lsp.automatic_servers_installation = false

-- Skip LSP server Solargraph, doesn't work unless we skip it in the beginning
-- otherwise it gets installed automatically!!
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "solargraph" })

-- Configure a server manually requires `:LvimCacheReset` to take effect!!
-- Ruby LSP
require("lvim.lsp.manager").setup("ruby_lsp", {
  cmd = { "ruby-lsp" },
  filetypes = { "ruby" },
  root_dir = require("lspconfig").util.root_pattern("Gemfile", ".git"),
  settings = {
    ruby = {
      formatting = true,
    }
  }
})

-- Additional Plugins
lvim.plugins = {
  { "junegunn/vim-easy-align" },
  { "tpope/vim-fugitive" },
  { "tpope/vim-surround" },
  {
    "folke/todo-comments.nvim",
    event = "BufRead",
    config = function()
      require("todo-comments").setup()
    end,
  },
  {
    "tzachar/cmp-tabnine",
    build = "./install.sh",
    dependencies = "hrsh7th/nvim-cmp",
    event = "InsertEnter",
  },
  {
    "mcauley-penney/tidy.nvim",
    config = function()
      require("tidy").setup()
    end
  },
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
  },

  -- themes --
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {},
  -- },
  -- { 'Mofiqul/vscode.nvim' },
  -- { 'rose-pine/neovim' },
  -- { "Mofiqul/dracula.nvim" },
  -- {
  --   "askfiy/visual_studio_code",
  --   priority = 100,
  --   config = function()
  --     require("visual_studio_code").setup({mode = "light"});
  --     vim.cmd([[colorscheme visual_studio_code]]);
  --   end,
  -- },
}
