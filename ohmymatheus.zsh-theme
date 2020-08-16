YS_VCS_PROMPT_PREFIX1=" %{$fg[blue]%}[branch]%{$reset_color%}"
YS_VCS_PROMPT_PREFIX2=" - %{$fg[green]%}"
YS_VCS_PROMPT_SUFFIX="%{$reset_color%}"
YS_VCS_PROMPT_DIRTY=" %{$fg[red]%}x"
YS_VCS_PROMPT_CLEAN=" %{$fg[yellow]%}👌"

# Git info
local git_info='$(git_prompt_info)'
ZSH_THEME_GIT_PROMPT_PREFIX="${YS_VCS_PROMPT_PREFIX1}${YS_VCS_PROMPT_PREFIX2}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$YS_VCS_PROMPT_SUFFIX"
ZSH_THEME_GIT_PROMPT_DIRTY="$YS_VCS_PROMPT_DIRTY"
ZSH_THEME_GIT_PROMPT_CLEAN="$YS_VCS_PROMPT_CLEAN"

 
PROMPT="😈%(?:%{$fg[green]%}➜ :%{$fg_bold[red]%}➜)"
PROMPT+='%{$fg[cyan]%}%c%{$reset_color%}$(git_prompt_info )'
