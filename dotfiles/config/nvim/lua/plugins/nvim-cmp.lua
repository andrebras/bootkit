return {
  "hrsh7th/nvim-cmp",
  opts = function()
    local cmp = require("cmp")
    return {
      mapping = {
        -- Enter key confirms selection
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        -- Ctrl+Space to trigger completion menu
        ["<C-Space>"] = cmp.mapping.complete(),
        -- Ctrl+e to close completion window
        ["<C-e>"] = cmp.mapping.abort(),
        -- Use Tab to navigate down through popup menu
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          else
            fallback()
          end
        end),
        -- Use Shift+Tab to navigate up through popup menu
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          else
            fallback()
          end
        end),
      },
    }
  end,
}
