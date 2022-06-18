require('lspconfig').hls.setup{
	on_attach = function(client)
		require('lspconfig').util.add_diagnostics(client)
	end
}
