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
        hook = function()
          require('mappings').neorg()
        end,
      },
    },
  }
}

