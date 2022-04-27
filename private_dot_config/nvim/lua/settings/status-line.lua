local gl = require('galaxyline')
local colors = require('galaxyline.theme').default
local condition = require('galaxyline.condition')
local gls = gl.section

local mode_color = {
   n = colors.red, 
   i = colors.green,
   v=colors.blue,
   [''] = colors.blue,
   V=colors.blue,
   c = colors.magenta,
   no = colors.red,
   s = colors.orange,
   S=colors.orange,
   [''] = colors.orange,
   ic = colors.yellow,
   R = colors.violet,
   Rv = colors.violet,
   cv = colors.red,
   ce=colors.red,
   r = colors.cyan,
   rm = colors.cyan, 
   ['r?'] = colors.cyan,
   ['!']  = colors.red,
   t = colors.red
}

gls.left[1] = {
  RainbowRed = {
    provider = function() 
      vim.api.nvim_command('hi GalaxyRainbowRed guifg='..mode_color[vim.fn.mode()])
      return ' '
    end,
    highlight = {colors.red,colors.bg}
  },
}
gls.left[2] ={
  FileIcon = {
    provider = 'FileIcon',
    condition = condition.buffer_not_empty,
    highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.bg},
  },
}
gls.left[3] = {
  FileName = {
    provider = {'FileName'},
    condition = condition.buffer_not_empty,
    highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color,colors.bg,'bold'}
  }
}

gls.left[4] = {
  GitIcon = {
    provider = function() return ' ' end,
    condition = condition.check_git_workspace,
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.violet,colors.bg },
  }
}

gls.left[5] = {
  GitBranch = {
    provider = 'GitBranch',
    condition = condition.check_git_workspace,
    separator = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.violet,colors.bg,'bold'},
  }
}

gls.left[6] = {
  DiffAdd = {
    provider = 'DiffAdd',
    condition = condition.hide_in_width,
    separator = ' ',
    icon = '  ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.green,colors.bg},
  }
}

gls.left[7] = {
  DiffModified = {
    provider = 'DiffModified',
    condition = condition.hide_in_width,
    separator = ' ',
    icon = ' 柳',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.orange,colors.bg},
  }
}

gls.left[8] = {
  DiffRemove = {
    provider = 'DiffRemove',
    separator = ' ',
    condition = condition.hide_in_width,
    icon = '  ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.red,colors.bg},
  }
}

gls.right[1] = {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.red,colors.bg}
  }
}

gls.right[2] = {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = {colors.yellow,colors.bg},
    separator_highlight = {'NONE',colors.bg},
  }
}

gls.right[3] = {
  DiagnosticHint = {
    provider = 'DiagnosticHint',
    icon = '  ',
    highlight = {colors.cyan,colors.bg},
    separator_highlight = {'NONE',colors.bg},
  }
}

gls.right[4] = {
  DiagnosticInfo = {
    provider = 'DiagnosticInfo',
    icon = '  ',
    highlight = {colors.blue,colors.bg},
    separator_highlight = {'NONE',colors.bg},
  }
}

gls.short_line_left[1] = {
  BufferType = {
    provider = 'FileTypeName',
    separtor = ' ',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.blue,colors.bg,'bold'}
  }
}

gls.short_line_left[2] = {
  SFileName = {
    provider =  'SFileName',
    condition = condition.buffer_not_empty,
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.fg,colors.bg,'bold'}
  }
}

gls.short_line_right[1] = {
  BufferIcon = {
    provider= 'BufferIcon',
    separator_highlight = {'NONE',colors.bg},
    highlight = {colors.fg,colors.bg}
  }
}
