local lspconfig = require'lspconfig'

local function attacher(client)
  print('Attaching LSP: ' .. client.name)
  client.resolved_capabilities.document_formatting = false
  client.resolved_capabilities.document_range_formatting = false
end

lspconfig.rust_analyzer.setup {
  -- Server-specific settings. See `:help lspconfig-setup`
  on_attack = attacher,
  settings = {
    ['rust-analyzer'] = {},
  },
}

