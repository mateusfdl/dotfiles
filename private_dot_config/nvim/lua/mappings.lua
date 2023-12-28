require "utils.mappings"

local M = {}

function M.system()
  nnoremap("<c-j>", ":m .+1<CR>==")
  nnoremap("<c-k>", ":m .-2<CR>==")
  inoremap("<c-j>", "<Esc>:m .+1<CR>==gi")
  inoremap("<c-k>", "<Esc>:m .-2<CR>==gi")
  vnoremap("<c-j>", ":m '>+1<CR>gv=gv")
  vnoremap("<c-k>", ":m '<-2<CR>gv=gv")
  nnoremap("<Left>", ":echoe 'this --> h'<CR>")
  nnoremap("<Right>", ":echoe 'this --> l'<CR>")
  nnoremap("<Up>", ":echoe 'this --> j'<CR>")
  nnoremap("<Down>", ":echoe 'this --> j'<CR>")
  nnoremap("<Leader>vv", ":so $HOME/.config/nvim/init.lua<CR>")

  inoremap("ii", "<esc>")

  map("<Leader>ts",
    [[:call system("tmux resize-pane -y 20 -t1 && tmux send -t1 'fd -e rb | entr -c ruby -r minitest/pride *_test.rb' c-j")]])
  map("<f1> :w<cr>", ":call system('tmux resize-pane -y 10 -t1 && tmux send -t1 'go test -v --bench .' c-j')<cr>")
  map("<C-e>", ":lua print(table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, 2, true)))")

  map("<Leader>fs", ":w<cr>")
  map("<Leader>k", ":lua require('goplayground.api').post()")
end

function M.comp()
  nnoremap('<Leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>')
  nnoremap('<Leader>D', '<cmd>lua vim.diagnostic.goto_next()<CR>')
  nnoremap('<Leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>')
end

function M.nvim_tree()
  nnoremap("<Leader>o", ":NvimTreeToggle<CR>")
  nnoremap("<Leader>O", ":NvimTreeFindFileToggle<CR>")
  nnoremap("<leader>r", ":NvimTreeRefresh<CR>")
  nnoremap("<leader>n", ":NvimTreeFindFile<CR>")
end

function M.telescope()
  nnoremap(";", ":lua require('telescope.builtin').find_files()<cr>")
  nnoremap("<leader>;", "<cmd>lua require('telescope.builtin').live_grep()<cr>")
  nnoremap("<leader>,", "<cmd>lua require('telescope.builtin').buffers()<cr>")
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
  nnoremap("gG", "<cmd>lua require('conform').format({ lsp_fallback = true, timeout = 500, async = true})<CR>")
  nnoremap("gr", "<cmd>lua vim.lsp.buf.references()<CR>")
  nnoremap("gR", "<cmd>lua vim.lsp.buf.rename()<CR>")
  nnoremap("gi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
  nnoremap("gt", "<cmd>lua vim.lsp.buf.type_definition()<CR>")
  nnoremap("gT", "<cmd>lua vim.lsp.buf.code_action()<CR>")
  nnoremap("<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
  nnoremap("<C-n>", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
  nnoremap("<C-p>", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")
end

function M.float_term()
  nnoremap("<C-d>", ":FloatermNew --height=33 --width=150 --title=-  lazygit<CR>")
  nnoremap("<Leader>ir", ":FloatermNew --height=30 --width=80 --title=-  irb<CR>")
end

function M.delve()
  nnoremap("<Leader>da", ":DlvAddBreakpoint<CR>")
  nnoremap("<Leader>dt", ":DlvAddTracepoint<CR>")
  nnoremap("<Leader>dc", ":DlvClearAll<CR>")
  nnoremap("<Leader>rn", ":DlvTest<CR>")
end

function M.vimGo()
  nnoremap("<Leader>Im", ":GoImpl")
  nnoremap("<Leader>gP", ":GoPlay<CR>")
end

function M.neorg()
  nnoremap("<Leader>d", ':Neorg keybind norg core.norg.qol.todo_items.todo.task_done<CR>')
end

function M.setup()
  M.system()
  M.comp()
  M.nvim_tree()
  M.telescope()
  M.telescope()
  M.easyalign()
  M.lsp()
  M.float_term()
  M.delve()
  M.vimGo()
end

return M
