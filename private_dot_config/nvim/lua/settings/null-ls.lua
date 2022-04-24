local null_ls = require("null-ls")

local formatting = null_ls.builtins.formatting

local diagnostics = null_ls.builtins.diagnostics

local sources = {
        diagnostics.erb_lint,
        diagnostics.golangci_lint,
        diagnostics.eslint,
        formatting.rubocop,
        formatting.goimports,
        formatting.prettier,
        formatting.rustfmt,
        formatting.rubocop,
        formatting.stylua,
        formatting.prettierd,
}

null_ls.setup({
    sources = sources
})