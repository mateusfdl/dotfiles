local g = vim.g
g.dashboard_session_directory = '~/.config/nvim/.sessions'
g.dashboard_default_executive ='telescope'
g.dashboard_custom_section = {
    a = {description = {"  Find File                 leader f f"}, command = "Telescope find_files"},
    b = {description = {"  Recents                   leader f h"}, command = "Telescope oldfiles"},
    -- c = {description = {"  Favourites                leader f r"}, command = "Telescope frecency"},
    d = {description = {"  Find Word                 leader f g"}, command = "Telescope live_grep"},
    e = {description = {"  New File                  leader e n"}, command = "DashboardNewFile"},
    f = {description = {"  Bookmarks                 leader f m"}, command = "Telescope marks"},
    g = {description = {"  Load Last Session         leader l  "}, command = "SessionLoad"},
    h = {description = {"  Update Plugins            leader u  "}, command = "PackerUpdate"},
    k = {description = {"  Settings                  leader ,  "}, command = "edit $MYVIMRC"},
    j = {description = {"  Exit                      leader q  "}, command = "exit"}
}

g.dashboard_custom_footer = {'type  :help<Enter>  or  <F1>  for on-line help'}
vim.cmd [[
augroup dashboard_au
     autocmd! * <buffer>
     autocmd User dashboardReady setlocal buftype=nofile
     autocmd User dashboardReady nnoremap <buffer> <leader>q <cmd>exit<CR>
     autocmd User dashboardReady nnoremap <buffer> <leader>u <cmd>PackerUpdate<CR>
     autocmd User dashboardReady nnoremap <buffer> <leader>l <cmd>SessionLoad<CR>
     autocmd User dashboardReady nnoremap <buffer> <leader>, <cmd>edit $MYVIMRC<CR>
augroup END
]]

-- vim.cmd("hi! link DashboardHeader Error")

g.dashboard_custom_header = {
  "                                   ",
            "   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣿⣶⣿⣦⣼⣆          ",
            "    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       ",
            "          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷    ⠻⠿⢿⣿⣧⣄     ",
            "           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    ",
            "          ⢠⣿⣿⣿⠈    ⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   ",
            "   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘  ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  ",
            "  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   ",
            " ⣠⣿⠿⠛ ⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  ",
            " ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇ ⠛⠻⢷⣄ ",
            "      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     ",
            "       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     ",
            "                                   ",
            "             N E O V I M           ",
       }

