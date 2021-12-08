local telescope = require("telescope")
telescope.setup {
  defaults = {
    layout_strategy = "flex",
    scroll_strategy = "cycle",
    selection_strategy = "row",
    winblend = 0,
    prompt_prefix = "🤔 ",
    selection_caret = "> ",
    border = {},
  }
}