# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="jborges"

# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment this to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
#plugins=(git heroku rails ruby tmux tmuxinator golang docker vagrant zsh-syntax-highlighting history-substring-search lein)
plugins=(git kubectl ruby golang docker history-substring-search zsh-syntax-highlighting terraform wakatime)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/sbin:/usr/sbin

# Aliases
# Cheat.sh
function cheat() {
	curl cheat.sh/$1
}
# Direct access to this config
alias zshconfig="vim ~/.zshrc"
## Use a long listing format ##
alias ll='ls -lah'
## Show hidden files ##
alias l.='ls -d .*'
## get rid of command not found ##
alias cd..='cd ..'
## a quick way to get out of current directory ##
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
## see open ports
alias openports="sudo lsof -i -n -P | grep TCP | grep LISTEN"
## Docker
alias doi="docker images"
alias dori="docker rmi"
alias dorc="docker rm"
alias dops="docker ps -a"
## Terraform
alias tf="terraform"
## Docker Containers
alias open_nestcli="docker run -it --rm -v `pwd`:/workspace nestjs/cli:6.3.0"
## Lazydocker
alias lzd="lazydocker"
# Git
alias gdst="git diff --stat"
alias guc="git ls-files --others --exclude-standard | xargs wc -l"

function wipe_container() {
    docker stop $1
    docker rm $1
}
## Docker Composer
alias dcom="docker-compose"
## Vagrant
alias v="vagrant"

# Fix for tmux colors
alias tmux="TERM=screen-256color-bce tmux"
alias jmux="TERM=screen-256color-bce tmux new -s main -n console"

# Tmuxinator
export EDITOR=vim

## History
HISTFILE=$HOME/.zsh_history    # enable history saving on shell exit
setopt APPEND_HISTORY          # append rather than overwrite history file.
HISTSIZE=10000000              # lines of history to maintain memory
SAVEHIST=10000000              # lines of history to maintain in history file.
setopt HIST_EXPIRE_DUPS_FIRST  # allow dups, but expire old ones when I hit HISTSIZE
setopt EXTENDED_HISTORY        # save timestamp and runtime information

# Github hub command line wrapper (commented cuz it breaks completion)
#alias git=hub

# bind UP and DOWN arrow keys
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Z - Directory Toggles
. ~/.oh-my-zsh/custom/plugins/z/z.sh

# Disabling start/stop output
stty -ixon -ixoff

# rbenv
if which rbenv > /dev/null; then eval "$(rbenv init - --no-rehash)"; fi

# Tmux
[ -z "$TMUX" ] && export TERM=xterm-256color

# MySQL 5.6
export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"

# PHP 7
export PATH="/usr/local/opt/php@7.3/bin:$PATH"
export PATH="/usr/local/opt/php@7.3/sbin:$PATH"

# Python
#export PATH="/usr/local/share/python:$PATH"

# Go
export GOPATH=$HOME/repos/go
export GOROOT=/usr/local/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# Scala
#export SBT_OPTS=-XX:MaxPermSize=512M

# Docker
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/gborges/.docker/machine/machines/default"
export DOCKER_MACHINE_NAME="default"

# Node (NVM) and NPM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh"  ] && . "$NVM_DIR/nvm.sh" # This loads nvm (slow)
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# AWS CLI
#source /usr/local/bin/aws_zsh_completer.sh

# Lazygit
alias lg="lazygit"

# For changing between Java versions
alias java_ls='/usr/libexec/java_home -V 2>&1 | grep -E "\d.\d.\d_\d\d" | cut -d , -f 1 | colrm 1 4 | grep -v Home'

function java_use() {
    export JAVA_HOME=$(/usr/libexec/java_home -v $1)
    export PATH=$JAVA_HOME/bin:$PATH
    java -version
}

# Git extras
function gstash() {
    git stash show -p stash@{$1}
}

# composer binaries
export PATH="$PATH:$HOME/.composer/vendor/bin"

# nginx command line
alias nginx.restart="sudo nginx -s stop && sudo nginx"

# set locale
export LC_ALL="en_AU.UTF-8"

# SK aliases
alias sksu="php -d memory_limit=-1 public/index.php etl update_stats scope_operational -v"
alias sksbu="php -d memory_limit=-1 public/index.php etl update_stats scope_business -v"
alias skcu="php -d memory_limit=-1 public/index.php etl update_catalog import_active scope_operational -v"
alias skcum="php -d memory_limit=-1 public/index.php etl update_catalog import_messages scope_operational -v"
alias skcbu="php -d memory_limit=-1 public/index.php etl update_catalog import_active scope_business -v"
alias skcbum="php -d memory_limit=-1 public/index.php etl update_catalog import_messages scope_business -v"
alias sks="php -d memory_limit=-1 public/index.php etl snapshot import_active scope_business -v"
alias skw="php -d memory_limit=-1 public/index.php etl update_wishlist import_active scope_global -v"
alias sktbr="php -d memory_limit=-1 public/index.php etl update_catalog_timeline import_active scope_business --with-recreate-index -v"

# iterm2 shell integration (disable for now because of tmux)
#test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# add my keys to SSH
ssh-add -K ~/.ssh/id_rsa_jborges82 &>/dev/null
ssh-add -K ~/.ssh/id_rsa_theiconic &>/dev/null

# added by travis gem
[ -f /Users/gborges/.travis/travis.sh ] && source /Users/gborges/.travis/travis.sh

# add virtualenvwrapper to path
#export WORKON_HOME=$HOME/.virtualenvs
#export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3 # using the brew one
#source `which virtualenvwrapper.sh`

# Anaconda
export PATH="/anaconda3/bin:$PATH"

# Add Visual Studio Code (code)
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# Dad jokes
alias dad="curl https://icanhazdadjoke.com/ && echo"
