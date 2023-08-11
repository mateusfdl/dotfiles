local M = {}

function M.on_attach(client, bufnr)
  enable_format_on_save(client, bufnr)
end

M.settings = {
  Lua = {
    diagnostics = {
      globals = { 'vim' },
    },
    workspace = {
      library = vim.api.nvim_get_runtime_file("", true),
      checkThirdParty = false
    },
  },
}

return M

