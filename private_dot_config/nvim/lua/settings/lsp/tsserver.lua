local lspconfig = require'lspconfig'
local ts_utils = require("nvim-lsp-ts-utils")

local function attacher(client, bufnr)
  print('Attaching LSP: ' .. client.name)
  ts_utils.setup({})
  ts_utils.setup_client(client)

   if client.resolved_capabilities.document_formatting then
      vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")
   end

  ts_utils.setup {
    debug = false,
    disable_commands = false,
    enable_import_on_completion = true,
    import_all_timeout = 5000,
    import_all_priorities = {
      buffers = 4, 
      buffer_content = 3,
      local_files = 2,
      same_file = 1,
    },
    import_all_scan_buffers = 100,
    import_all_select_source = false,

    eslint_enable_code_actions = false,
    eslint_enable_disable_comments = true,
    eslint_bin = "eslint",
    eslint_enable_diagnostics = false,
    eslint_opts = {},

    enable_formatting = false,
    formatter = "prettierd",
    formatter_opts = {},

    update_imports_on_move = false,
    require_confirmation_on_move = false,
    watch_dir = nil,

    filter_out_diagnostics_by_severity = {},
    filter_out_diagnostics_by_code = {},
  }

  ts_utils.setup_client(client)
end

lspconfig.tsserver.setup{
    on_attach = attacher,
    flags = { debounce_text_changes = 150 },
}
