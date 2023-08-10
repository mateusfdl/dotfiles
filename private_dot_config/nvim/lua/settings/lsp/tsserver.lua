local M = {}

function M.on_attach(client, bufnr)
    local buff = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf)
    local params = { command = "_typescript.organizeImports", arguments = { buff }, title = "" }
    vim.lsp.buf.execute_command(params)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gs", ":OrganizeImports<CR>", {silent = true})
    commands = {
      OrganizeImports = {
        organize_imports,
        description = "Organize Imports"
      }
    }
end

return M