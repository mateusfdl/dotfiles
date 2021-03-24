let g:rspec_command = "call VtrSendCommand('rspec -I . {spec}}')"
map <Leader>rr :call RunCurrentSpecFile()<CR>
map <Leader>rn :call RunNearestSpec()<CR>
