function set_keybind(mode, lhs, rhs, opts)
  local options = { silent = true }

  if opts then
    options = vim.tbl_extend('force', options, opts)
  end

  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

function buf_set_keybind(bufnr, mode, lhs, rhs, opts)
  vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts or {
    silent = true,
  })
end

function map(bind, command)
  set_keybind("", bind, command)
end

function smap(bind, command)
  set_keybind("s", bind, command)
end

function imap(bind, command)
  set_keybind("i", bind, command)
end

function nmap(bind, command)
  set_keybind("n", bind, command)
end

function omap(bind, command)
  set_keybind("o", bind, command)
end

function xmap(bind, command)
  set_keybind("x", bind, command)
end

function noremap(bind, command)
  set_keybind("", bind, command, { noremap = true })
end

function inoremap(bind, command)
  set_keybind("i", bind, command, { noremap = true })
end

function nnoremap(bind, command)
  set_keybind("n", bind, command, { noremap = true })
end

function vnoremap(bind, command)
  set_keybind("v", bind, command, { noremap = true })
end

function xnoremap(bind, command)
  set_keybind("x", bind, command, { noremap = true })
end

function tnoremap(bind, command)
  set_keybind("t", bind, command, { noremap = true })
end

return {
  imap = imap,
  nmap = nmap,
  omap = omap,
  xmap = xmap,
  noremap = noremap,
  inoremap = inoremap,
  nnoremap = nnoremap,
  vnoremap = vnoremap,
  xnoremap = xnoremap,
  buf_set_keybind = buf_set_keybind,
}
