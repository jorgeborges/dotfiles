# powerline10k
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# $PATH
# export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

if [[ ":$PATH:" != *":/usr/local/sbin:"* ]]; then
  export PATH=/usr/local/sbin:$PATH
fi

if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
  export PATH=$HOME/bin:$PATH
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git docker docker-compose kubectl you-should-use z zsh-autosuggestions zsh-syntax-highlighting) # zsh-syntax-highlighting MUST be the last plugin

fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
source $ZSH/oh-my-zsh.sh

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"
# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR='vim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

## updates $PATH for other programs
# PHP 7.3
# if [[ ":$PATH:" != *":/usr/local/opt/php@7.3/bin:"* ]]; then
  # export PATH="/usr/local/opt/php@7.3/bin:$PATH"
  # export PATH="/usr/local/opt/php@7.3/sbin:$PATH"
# fi

# Python (pyenv)
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Node version manager (NVM)
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# logo-ls
alias ils='logo-ls'
alias ila='logo-ls -A'
alias ill='logo-ls -al'
# logo-ls equivalents with Git Status on by Default
alias ilsg='logo-ls -D'
alias ilag='logo-ls -AD'
alias illg='logo-ls -alD'
# see all open ports
alias openports="sudo lsof -i -n -P | grep TCP | grep LISTEN"
## Docker
alias doi="docker images"
alias dori="docker rmi"
alias dorc="docker rm"
alias dops="docker ps -a"
## Terraform (OpenTofu)
alias tf="tofu"
## Python General Venv
alias genenv="source ~/general_venv/general/bin/activate"
## tmuxinator
alias thami="tmuxinator hamiware"

# powerline10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# p10k custom prompts colors
typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=7
typeset -g POWERLEVEL9K_VIRTUALENV_BACKGROUND=34
typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=true
typeset -g POWERLEVEL9K_PYENV_FOREGROUND=7

# my custom p10k prompt
function prompt_my_altera_prompt() {
  p10k segment -t "%{$reset_color%}%{$fg[red]%}❯%{$reset_color%}%{$fg[yellow]%}❯%{$reset_color%}%{$fg[cyan]%}❯%{$reset_color%}"
}
# add the altera prompt and config
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS+=my_altera_prompt
typeset -g POWERLEVEL9K_MY_ALTERA_PROMPT_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=
typeset -g POWERLEVEL9K_MY_ALTERA_PROMPT_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=
typeset -g POWERLEVEL9K_MY_ALTERA_PROMPT_LEFT_{LEFT,RIGHT}_WHITESPACE=

# Ruby - rbenv
eval "$(rbenv init --no-rehash - zsh)"

# pnpm
export PNPM_HOME="/Users/jorgeborges/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# fuzzy autocomplete
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Hamiware ENV
source ~/.config/hamiware/secrets.env

# psql
export PATH="/usr/local/opt/libpq/bin:$PATH"

#PATH=~/.console-ninja/.bin:$PATH
