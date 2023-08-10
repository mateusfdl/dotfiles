do
  local lint = require('lint')
  lint.linters_by_ft = {
    dockerfile = { 'hadolint', },
    lua = { 'luacheck', }
  }

  vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufEnter', 'BufLeave' }, {
    group = vim.api.nvim_create_augroup('lint', { clear = true }),
    callback = function() lint.try_lint() end,
  })
end
