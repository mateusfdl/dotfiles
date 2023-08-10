require 'nvim-treesitter.configs'.setup {
  ensure_installed = { "norg" },
  highlight = {
    enable = true,
    disable = { "c" },
  },
}
