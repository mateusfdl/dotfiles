local nvim_lsp = require("lspconfig")
local ts_utils = require("nvim-lsp-ts-utils")

nvim_lsp.tsserver.setup {
    on_attach = function(client, bufnr)
        client.resolved_capabilities.document_formatting = false
        client.resolved_capabilities.document_range_formatting = false

        ts_utils.setup {
            debug = false,
            disable_commands = false,
            enable_import_on_completion = true,
            import_on_completion_timeout = 5000,
            eslint_enable_code_actions = true,
            eslint_bin = "eslint",
            eslint_args = {"-f", "json", "--stdin", "--stdin-filename", "$FILENAME"},
            eslint_enable_disable_comments = true,
            eslint_enable_diagnostics = true,
            eslint_diagnostics_debounce = 250,
            enable_formatting = true,
            formatter = "prettier",
            formatter_args = {"--stdin-filepath", "$FILENAME"},
            format_on_save = true,
            no_save_after_format = false,

            complete_parens = false,
            signature_help_in_parens = true,

            update_imports_on_move = false,
            require_confirmation_on_move = false,
            watch_dir = "/src",
        }

        ts_utils.setup_client(client)

        vim.api.nvim_buf_set_keymap(bufnr, "n", "gs", ":TSLspOrganize<CR>", {silent = true})
        vim.api.nvim_buf_set_keymap(bufnr, "n", "qq", ":TSLspFixCurrent<CR>", {silent = true})
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", ":TSLspRenameFile<CR>", {silent = true})
        vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", ":TSLspImportAll<CR>", {silent = true})
    end
}

local eslint = {
    lintCommand = "eslint_d -f unix --stdin --stdin-filename ${INPUT}",
    lintStdin = true,
    lintFormats = {"%f:%l:%c: %m"},
    lintIgnoreExitCode = true,
    formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
    formatStdin = true
}

local prettier = {
    formatCommand = "prettier"
}

nvim_lsp.efm.setup{
    cmd = {"efm-langserver"},
    on_attach = function(client)
        client.resolved_capabilities.rename = false
        client.resolved_capabilities.hover = false
        vim.cmd [[augroup lsp_formatting]]
        vim.cmd [[autocmd!]]
        vim.cmd [[autocmd BufWritePre <buffer> :lua vim.lsp.buf.formatting_sync()]]
        vim.cmd [[augroup END]]
    end,
    init_options = {
    documentFormatting = true,
},
    settings = {
        rootMarkers = {vim.loop.cwd()},
        languages = {
            javascript = { prettier, eslint },
            typescript = { prettier, eslint },
	    typescriptreact = { prettier, eslint },
	    javascriptreact = { prettier, eslint },
        }
    }
}
