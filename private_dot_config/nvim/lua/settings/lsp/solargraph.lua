local lspconfig = require'lspconfig'

local function attacher(client)
  print('Attaching LSP: ' .. client.name)
end

lspconfig.jsonls.setup{
  on_attach = attacher
}

lspconfig.solargraph.setup{
  settings = {
    solargraph = {
      commandPath = '/Users/joaomatheusfurtadodelima/.asdf/shims/solargraph',
      diagnostics = true,
      completion = true,
      autoformat = true,
      autoimport = true,
      lint = true,
      formating = true,
      documentation = true,
      hover = true,
      signature = true,
      references = true,
      rename = true,
      logLevel = 'warn',
    }
  },

  on_attach = attacher
}
