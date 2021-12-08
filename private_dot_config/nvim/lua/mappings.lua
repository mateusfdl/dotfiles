require "utils.mappings"

local M = {}

function M.system()
    nnoremap("<Left>", ":echoe 'this --> h'<CR>")
    nnoremap("<Right>", ":echoe 'this --> l'<CR>")
    nnoremap("<Up>", ":echoe 'this --> j'<CR>")
    nnoremap("<Down>", ":echoe 'this --> j'<CR>")

    inoremap("ii", "<esc>")

    map("<f4> :w<cr>", ":call system('tmux resize-pane -y 20 -t2 && tmux send -t2 'ruby -r minitest/pride *_test.rb' c-j')<cr>")
    map("<f1> :w<cr>", ":call system('tmux resize-pane -y 10 -t1 && tmux send -t1 'go test -v --bench .' c-j')<cr>")
end

function M.nvim_tree()
    nnoremap("<Leader>o", ":NvimTreeToggle<CR>")  
    nnoremap("<leader>r", ":NvimTreeRefresh<CR>")  
    nnoremap("<leader>n", ":NvimTreeFindFile<CR>")  
end

function M.telescope()
    nnoremap(";", ":lua require('telescope.builtin').find_files()<cr>")
    nnoremap("<leader>;",  "<cmd>lua require('telescope.builtin').live_grep()<cr>")
    nnoremap("<leader>,",  "<cmd>lua require('telescope.builtin').buffers()<cr>") 
    nnoremap("<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>")
end

function M.easyalign()
    nmap("gd", ":EasyAlign") 
    xmap("ga", ":EasyAlign")
end

function M.setup()
    M.system()
    M.nvim_tree()
    M.telescope()
    M.telescope()
    M.easyalign()
end

return M


