require("utils.mappings")
local M = {}

_G.organize_imports = function()
  vim.lsp.buf.execute_command {
    command = '_typescript.organizeImports',
    arguments = {
      vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
    }
  }
end
vim.cmd('command! OrganizeImports lua organize_imports()')

function M.on_attach(_, bufnr)
  buf_set_keybind(bufnr, "n", "gs", ":OrganizeImports<CR>")
end

return M
