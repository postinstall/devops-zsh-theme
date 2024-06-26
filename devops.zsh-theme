# devops.zsh-theme
#
# Author: Sascha Mario Klein
# E-Mail: sascha@neuroticfish.com
#
# Requirements:
# - oh-my-zsh - https://github.com/ohmyzsh/ohmyzsh
# - homebrew - https://brew.sh/index_de
# - yq - https://github.com/mikefarah/yq

# disable virtualenv prompt injection
export VIRTUAL_ENV_DISABLE_PROMPT=yes

# set the git_prompt_info text
ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[yellow]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# design
ARROW_BG=235
ARROW_FG=242

function git_branch_name()
{
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
  if [[ $branch == "" ]];
  then
    :
  else
    echo ' ('$branch')'
  fi
}

# parse kubeconfig
kubeprompt() {
    if [[ -z "$KUBECONFIG" ]]; then
        export kubeconfig="$HOME/.kube/config"
    else
        export kubeconfig="$KUBECONFIG"
    fi
    if [ -f $kubeconfig ]; then
        export kubecontext="$(yq '.current-context' $kubeconfig)"
        export kubenamespace="$(yq '.contexts | map(select(.name == env(kubecontext))) | .[0].context.namespace' $kubeconfig)"
        ZSH_KUBECTL_PROMPT="$kubecontext/$kubenamespace"
        echo $ZSH_KUBECTL_PROMPT
    else
        echo "N/A"
    fi
}

# display current context
ctx() {
    if [[ -z "$KUBECONFIG" ]]; then
        export kubeconfig="$HOME/.kube/config"
    else
        export kubeconfig="$KUBECONFIG"
    fi
    if [ -f $kubeconfig ]; then
        export kubecontext="$(yq '.current-context' $kubeconfig)"
        yq '.contexts[].name' $kubeconfig | grep --color=always "$kubecontext\|$"
    fi
}

# unset aws vars
awsunset() {
    for i in `set | grep -i AWS_ | cut -d"=" -f1`; do
        unset $i
    done
}

# display current namespace
ns() {
    echo $ZSH_KUBECTL_PROMPT
}

# display triangle
triangle() {
   echo $'\ue0b0'
}

# display arrow
arrow() {
   echo $'\ue0b1'
}

# display seperator
sep() {
   echo "%{$reset_color%}%{$BG[$ARROW_BG]%}%{$FG[$ARROW_FG]%}$(arrow)%{$fg[white]%}"
}

# display end seperator
endsep() {
   echo "%{$reset_color%}%{$FG[$ARROW_BG]%}%{$bg[bloack]%}$(triangle)%{$fg[white]%}"
}

# modify git prompt
gitprompt() {
    if [ "$(git_branch_name)" != "" ]; then
        echo " $(sep)%{$fg[yellow]%}$(git_branch_name)%{$reset_color%}%{$BG[$ARROW_BG]%}%{$FG[$ARROW_FG]%}"
    fi
}

# define python venv prompt
venvprompt() {
    if [ "$VIRTUAL_ENV" != "" ]; then
        echo " $(sep) %{$FG[099]%}[${VIRTUAL_ENV##*/}]%{$reset_color%}%{$BG[$ARROW_BG]%}%{$FG[$ARROW_FG]%}"
    fi
}

awsvault() {
    if [[ ! -z $AWS_VAULT ]]; then
        epoch=$(date -j -u -f %Y-%m-%dT%H:%M:%SZ "${AWS_CREDENTIAL_EXPIRATION}" +%s)
        now=$(date +%s)
        valid="$(($epoch-$now))"
        if [ "${valid}" -gt "0" ]; then
            echo "[${AWS_VAULT}:${valid}s] "
        else
            echo "%{$fg[red]%}[${AWS_VAULT}:N/A]%{$reset_color%} "
        fi
    fi
}

# putting it all together
autoload -U colors; colors
NEWLINE=$'\n'
PROMPT='${NEWLINE}%{$BG[$ARROW_BG]%}%{$fg[cyan]%} $(whoami)@$(hostname -s) $(awsvault)$(sep) %{$fg[green]%}%~$(venvprompt)$(gitprompt) $(endsep) '

if [ "$(kubeprompt)" != "N/A" ]; then
    RPROMPT='%{$fg[red]%}($(kubeprompt))%{$reset_color%}'
fi
