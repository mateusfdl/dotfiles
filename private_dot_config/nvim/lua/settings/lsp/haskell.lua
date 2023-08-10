local M = {}

function M.on_attach(client)
	require('lspconfig').util.add_diagnostics(client)
end

return M