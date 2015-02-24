JB dotfiles
========

My configuration files for Vim, tmux, git, etc etc.

## Features

### Todoist Tasks script

![Todoist Tasks](https://github.com/jorgeborges/dotfiles/blob/master/assets/img/todoist.png)

I place this on my tmux status bar. It displays a resume of open tasks for a Todoist account. Configurable via config file with API token. Should be read as:
* ◯ overdue
* ✕ for today
* ⃤  are scheduled
* △ no due date or icebox

Ruby gem dependencies include REST Client and Redis
