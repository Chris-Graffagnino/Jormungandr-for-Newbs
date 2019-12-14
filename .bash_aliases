# .bash_aliases

alias ll='ls -l'
alias l='ls'

alias vi="nvim"
alias python="python3"
alias pip="pip3"

# git
alias gb="git branch"
alias gpum="git pull upstream master"
alias gpom="git pull origin master"
alias gpo="git push origin"
alias gcom="git checkout master"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gst="git status"
alias gad="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gmm="git merge master"

# Django
alias mng="python manage.py"

# misc
alias claer="clear"

f() { find . -iname "*$1*"; }
