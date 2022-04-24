local lspconfig = require'lspconfig'

lspconfig.solargraph.setup{
  settings = {
    solargraph = {
      commandPath = '/Users/joaomatheusfurtadodelima/.asdf/shims/solargraph',
      logLevel = 'warn',
    }
  },
  on_attach = attacher
}

local function attacher(client, bufnr)
  print('Attaching LSP: ' .. client.name)
  client.resolved_capabilities.document_formatting = false
  client.resolved_capabilities.document_range_formatting = false
end
