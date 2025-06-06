return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    -- Set the component and section separators as empty strings to haven
    -- simple vertical separators instead of angled separators.
    options = {
      theme = "auto",
      component_separators = "",
      section_separators = "",
    },
    -- Replaces the mode text [normal, insert, etc...] with the vim icon and
    -- remove the last section (clock).
    sections = {
      lualine_a = {
        {
          "mode",
          fmt = function()
            return ""
          end,
        },
      },
      lualine_z = {},
    },
  },
}
