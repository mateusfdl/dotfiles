vim.g["go_fmt_command"] = "goimports"

vim.cmd("autocmd FileType go setlocal shiftwidth=4")
vim.cmd("autocmd FileType go setlocal tabstop=4")