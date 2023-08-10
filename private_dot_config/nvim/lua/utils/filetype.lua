
function isGo()
  return vim.bo.filetype == "go"
end

function isLua()
  return vim.bo.filetype == "lua"
end

function isRuby()
  return vim.bo.filetype == "ruby"
end

return {
  isGo = isGo,
  isRuby = isRuby,
  isLua = isLua,
}

