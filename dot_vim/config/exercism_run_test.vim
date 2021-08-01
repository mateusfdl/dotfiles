map <f4> :w<cr>:call system("tmux resize-pane -y 20 -t2 && tmux send -t2 'ruby -r minitest/pride *_test.rb && tmux resize-pane -Z -t1' c-j")<cr>
