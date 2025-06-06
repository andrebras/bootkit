return {
  "dense-analysis/ale",
  config = function()
    vim.g.ale_lint_on_save = 1
    vim.g.ale_lint_on_text_changed = "never"
    vim.g.ale_set_balloons = 0
    vim.g.ale_virtualtext_cursor = 0
    vim.g.ale_echo_cursor = 0
    vim.g.ale_sign_error = 0
    vim.g.ale_sign_warning = 0

    -- Configure ALE fixers:
    --   Trim trailing whitespace globally
    --   Use Prettier for JavaScript
    --   RuboCop for Ruby
    vim.g.ale_fixers = {
      ["*"] = { "trim_whitespace" },
      ["javascript"] = { "prettier" },
      ["ruby"] = { "rubocop" },
    }

    -- Enable auto-fixing on save
    vim.g.ale_fix_on_save = 1
  end,
}
