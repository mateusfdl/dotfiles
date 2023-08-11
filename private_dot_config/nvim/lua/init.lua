local M = {}
local fn = vim.fn
local execute = vim.api.nvim_command

vim.g.mapleader = ","

local function packer_init()
  local install_path = fn.stdpath "data" .. "/site/pack/packer/opt/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    execute("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
  end
  vim.cmd [[packadd! packer.nvim]]
  vim.cmd "autocmd BufWritePost plugins.lua PackerCompile"
end

local function nvim_init()
  require "impatient"
end

function M.setup()
  ---nvim_init()

  packer_init()

  --require("plugin.packer_compiled")

  require("plugins")
  require("settings.init").setup()
  require("mappings").setup()

  vim.defer_fn(function()
    require("plugins")
  end, 0)
end

return M
