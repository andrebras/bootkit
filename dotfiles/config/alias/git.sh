# Git Log Formats
_git_log_oneline_format='%C(green)%h%C(reset) %C(blue bold)(%ar by %an) %C(reset)%s %C(bold red)%d%C(reset)'
_git_log_brief_format='%C(green)%h%C(reset) %s%C(red)%d%C(reset)%n'

# Git
alias g='git'

# List last 15 used branches
alias gb="git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'"

# Checkout
alias gco='git checkout'

# Log
alias glg='git log --color=always --topo-order --all --graph --pretty=format:${_git_log_brief_format}'
alias glo='git log --color=always --topo-order --pretty=format:${_git_log_oneline_format}'
alias gll='git log --color=always --topo-order --pretty=format:${_git_log_oneline_format} -n25'


# Working Copy
alias gss='git status --ignore-submodules=${_git_status_ignore_submodules} --short'
alias gws='git status --ignore-submodules=${_git_status_ignore_submodules}'

# Prezto has a lot Git alias and we need ghostscript (gs) to work instead of stashing shit!
# unalias gs
