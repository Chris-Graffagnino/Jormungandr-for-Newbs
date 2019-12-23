# bash_aliases

# Cast Python2 aside and don't look back
alias python="python3"
alias pip="pip3"

# git
alias gb="git branch"
alias gpom="git pull origin master"
alias gcom="git checkout master"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gst="git status"
alias gad="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gmm="git merge master"

# misc
alias claer="clear"

f() { find . -iname "*$1*"; }
