local nvim_lsp = require("lspconfig")

nvim_lsp.tsserver.setup {
    on_attach = attacher
}

local function attacher(client, bufnr)
  print('Attaching LSP: ' .. client.name)
  client.resolved_capabilities.document_formatting = false
  client.resolved_capabilities.document_range_formatting = false
end
