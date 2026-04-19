return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      ["<CR>"] = { "accept", "fallback" },
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
      ["<C-Space>"] = { "show" },
      ["<C-e>"] = { "cancel" },
    },
  },
}
