local nvim_lsp = require("lspconfig")

local function organize_imports()
  local params = {
    command = "_typescript.organizeImports",
    arguments = {vim.api.nvim_buf_get_name(0)},
    title = ""
  }
  vim.lsp.buf.execute_command(params)
end


nvim_lsp.tsserver.setup {
    on_attach = function(client, bufnr)
      print('Attaching LSP: ' .. client.name)
      client.resolved_capabilities.document_formatting = false
      client.resolved_capabilities.document_range_formatting = false

      vim.api.nvim_buf_set_keymap(bufnr, "n", "gs", ":OrganizeImports<CR>", {silent = true})
    end,
    commands = {
    OrganizeImports = {
      organize_imports,
      description = "Organize Imports"
    }
  }
}

