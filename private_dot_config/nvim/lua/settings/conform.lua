vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    require("conform").format({ bufnr = args.buf })
  end,
})

require("conform").setup({
  formatters_by_ft = {
    javascript = { { "prettier", "prettierd" } },
    typescript = { { "prettier", "prettierd" } },
  },
})
