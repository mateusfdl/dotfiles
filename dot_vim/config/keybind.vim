nnoremap <Left> :echoe "this --> h"<CR>
nnoremap <Right> :echoe "this --> l"<CR>
nnoremap <Up> :echoe "this --> k"<CR>
nnoremap <Down> :echoe "this --> j"<CR>

"STOP BLOWING MA MIND

map <tab><tab> :<C-u>call search('^\s*$\\|\%$', 'W')<CR>
nnoremap <leader>cn :tn<cr> " next definition
inoremap ii <esc>
nnoremap cn <S-v>/\n\n<CR>
noremap <Leader>s :update<CR>
