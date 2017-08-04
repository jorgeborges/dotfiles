#!/usr/bin/env zsh
#local return_code="%(?..%{$fg[red]%}%? ↵%{$reset_color%})"

# j9 by Jorge Borges

# Use with a dark background and 256-color terminal!

# You can set your computer name in the ~/.box-name file if you want.

# Borrowing shamelessly from these oh-my-zsh themes:
#   fino
#   bira
#   robbyrussell
#   muse
#   ingo
#
# Also borrowing from http://stevelosh.com/blog/2010/02/my-extravagant-zsh-prompt/

setopt promptsubst

autoload -U add-zsh-hook

function prompt_char {
    #git status >/dev/null 2>/dev/null && echo '± ' && return
    #hg root >/dev/null 2>/dev/null && echo '☿ ' && return
    echo '❯ '
}

function box_name {
    [ -f ~/.box-name ] && cat ~/.box-name || hostname -s
}


local rvm_ruby='‹$(rvm-prompt i v g)›%{$reset_color%}'
local current_dir='${PWD/#$HOME/~}'
local git_info='$(git_prompt_info)'


PROMPT="%{$FG[040]%}%n%{$reset_color%}%{$FG[239]%}@%{$reset_color%}%{$FG[033]%}$(box_name)%{$reset_color%} %{$FG[239]%}in%{$reset_color%} %{$terminfo[bold]$FG[226]%}${current_dir} %{$reset_color%}${git_info}
%F{green}$(prompt_char)%f"


ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[051]%}\uE0A0:%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[082]%}✚%{$reset_color%}a"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[166]%}✹%{$reset_color%}m"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[160]%}✖%{$reset_color%}d"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[220]%}➜%{$reset_color%}r"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[082]%}═%{$reset_color%}um"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[190]%}✭%{$reset_color%}ut"

