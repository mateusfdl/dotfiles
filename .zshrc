
export PATH=$PATH=$HOME/pear/bin:$PATH

export ZSH="/home/donamaid/.oh-my-zsh"

export TERM="xterm-256color"

export LANG=en_US.UTF-8

ZSH_THEME="ohmymatheus"

. $HOME/.asdf/asdf.sh

plugins=(docker docker-compose git ruby)

source $ZSH/oh-my-zsh.sh
source $HOME/.cargo/env
source $HOME/.zsh.d/alias-docker.zsh
source $HOME/.zsh.d/alias-git.zsh

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

alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME'
alias home='cd $HOME'
alias ps='docker-compose ps -a'
