require('neorg').setup {
  load = {
    ['core.esupports.metagen'] = {
    },
    ['core.concealer'] = {
      config = {
        folds = true,
        icon_preset = "varied",
        icons = {
          todo = {
            done = {
              icon = "",
            },
            urgent = {
              icon = "",
            },
          }
        }
      }
    },
    ['core.defaults'] = {},
    ['core.completion'] = { config = { engine = 'nvim-cmp' } },
    ['core.dirman'] = {
      config = {
        workspaces = {
          work = "~/livefire/notes",
          studies = "~/Documents/org/studies/home",
          notes = "~/Documents/org/notes/home",
        },
        default_workspace = "notes",
      }
    },
    ['core.keybinds'] = {
      config = {
        default_keybinds = false,
        hook = function(keybinds)
          keybinds.remap_event("norg", "n", "<Leader>td", "core.qol.todo_items.todo.task_done<CR>")
          keybinds.remap_event("norg", "n", "<Leader>tu", "core.qol.todo_items.todo.task_undone<CR>")
          keybinds.remap_event("norg", "n", "<Leader>tp", "core.qol.todo_items.todo.task_pending<CR>")
          keybinds.remap_event("norg", "n", "<Leader>th", "core.qol.todo_items.todo.task_on_hold<CR>")
          keybinds.remap_event("norg", "n", "<Leader>tc", "core.qol.todo_items.todo.task_cancelled<CR>")
          keybinds.remap_event("norg", "n", "<Leader>tr", "core.qol.todo_items.todo.task_recurring<CR>")
          keybinds.remap_event("norg", "n", "<Leader>ti", "core.qol.todo_items.todo.task_important<CR>")
        end,
      },
    },
  }
}

