local lib = require("nvim-tree.lib")
local map = vim.keymap.set

local node_under_cursor = function()
  return lib.get_node_at_cursor()
end

local git_add = function()
  local node = node_under_cursor()
  local gs = node.git_status

  if gs == "??" or gs == "MM" or gs == "AM" or gs == " M" then
    vim.cmd("silent !git add " .. node.absolute_path)
  elseif gs == "M " or gs == "A " then
    vim.cmd("silent !git restore --staged " .. node.absolute_path)
  end

  lib.refresh_tree()
end

local git_restore = function()
  vim.cmd("silent !git restore " .. node_under_cursor().absolute_path)

  lib.refresh_tree()
end

require("nvim-tree").setup({
  filters = {
    custom = { "\\.git$", "\\.node_modules" },
  },
  git = {
    ignore = false,
  },
  renderer = {
    icons = {
      glyphs = {
        git = {
          unstaged = "+",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "?",
          deleted = "",
          ignored = "◌",
        }
      }
    }
  },
  diagnostics = {
    enable = true,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    }
  },
  actions = {
    open_file = {
      quit_on_open = true
    }
  },
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")

    api.config.mappings.default_on_attach(bufnr)

    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, buffer = bufnr, silent = true, nowait = true }
    end
    map('n', 'ggA', git_add, opts('Git Add'))
    map('n', 'ggR', git_restore, opts('Git Restore'))
  end,
})
