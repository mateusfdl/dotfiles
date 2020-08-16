
export PATH=$PATH=$HOME/pear/bin:$PATH

export ZSH="/home/matheus/.oh-my-zsh"

export TERM="xterm-256color"

export LANG=en_US.UTF-8

ZSH_THEME="ohmymatheus"

. $HOME/.asdf/asdf.sh

plugins=(git ruby)

source $ZSH/oh-my-zsh.sh
source $HOME/.cargo/env

if [ -z "$TMUX" ]; then
    base_session='my_session'
    # Create a new session if it doesn't exist
    tmux has-session -t $base_session || tmux new-session -d -s $base_session
    # Are there any clients connected already?
    client_cnt=$(tmux list-clients | wc -l)
    if [ $client_cnt -ge 1 ]; then
        session_name=$base_session"-"$client_cnt
        tmux new-session -d -t $base_session -s $session_name
        tmux -2 attach-session -t $session_name \; set-option destroy-unattached
    else
        tmux -2 attach-session -t $base_session
    fi
fi
alias config='/usr/bin/git --git-dir=/home/matheus/.dotfiles/ --work-tree=/home/matheus'
