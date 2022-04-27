require "utils.mappings"

local M = {}

function M.system()
    nnoremap("<Left>", ":echoe 'this --> h'<CR>")
    nnoremap("<Right>", ":echoe 'this --> l'<CR>")
    nnoremap("<Up>", ":echoe 'this --> j'<CR>")
    nnoremap("<Down>", ":echoe 'this --> j'<CR>")
    nnoremap("<Leader>vv", ":so $HOME/.config/nvim/init.lua<CR>")

    inoremap("ii", "<esc>")

    map("<f4> :w<cr>", ":call system('tmux resize-pane -y 20 -t2 && tmux send -t2 'ruby -r minitest/pride *_test.rb' c-j')<cr>")
    map("<f1> :w<cr>", ":call system('tmux resize-pane -y 10 -t1 && tmux send -t1 'go test -v --bench .' c-j')<cr>")
    map("<C-e>", ":lua print(table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, 2, true)))" )

    map("<Leader>fs", ":w<cr>")
    map("<Leader>k", ":lua require('goplayground.api').post()")
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
    nmap("<leader>gd", ":EasyAlign") 
    xmap("<leader>ga", ":EasyAlign")
end

function M.lsp()
  nnoremap("gd", "<cmd>lua vim.lsp.buf.definition()<CR>")  
  nnoremap("gD", "<cmd>lua vim.lsp.buf.declaration()<CR>")  
  nnoremap("K", "<cmd>lua vim.lsp.buf.hover()<CR>")  
  nnoremap("gf", "<cmd>lua vim.lsp.buf.document_symbol()<CR>")
  nnoremap("gF", "<cmd>lua vim.lsp.buf.workspace_symbol()<CR>")
  nnoremap("gG", "<cmd>lua vim.lsp.buf.formatting_seq_sync(nil, 2000)<CR>")
  nnoremap("gr", "<cmd>lua vim.lsp.buf.references()<CR>")  
  nnoremap("gR", "<cmd>lua vim.lsp.buf.rename()<CR>")
  nnoremap("gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")  
  nnoremap("gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  nnoremap("gT", "<cmd>lua vim.lsp.buf.code_action()<CR>")
  nnoremap("<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>") 
  nnoremap("<C-n>", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>") 
  nnoremap("<C-p>", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")  

  vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
  vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
  vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
  vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
  vim.api.nvim_set_keymap("i", "<CR>", "compe#confirm({ 'keys': '<CR>', 'select': v:true })", { expr = true })
end

function M.float_term()
  nnoremap("<C-d>", ":FloatermNew --height=33 --width=150 --title=-  lazygit<CR>")
  nnoremap("<Leader>ir", ":FloatermNew --height=30 --width=80 --title=-  irb<CR>")
end

function M.setup()
    M.system()
    M.nvim_tree()
    M.telescope()
    M.telescope()
    M.easyalign()
    M.lsp()
    M.float_term()
end

return M


