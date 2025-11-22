

# Load Angular CLI autocompletion.
#source <(ng completion script)

# Add .NET global tools (like Tye) to PATH.
export PATH=$HOME/.dotnet/tools:$PATH


#. /opt/homebrew/opt/asdf/libexec/asdf.sh

# Python
PYTHONPATH="/Library/Frameworks/Python.framework/Versions/3.13/bin/python3.13"
export PYTHONPATH

# Neovim
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# Node Version Manager (NVM)
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# My aliases

alias whichport="sudo lsof -i -P | grep LISTEN | grep :$PORT"
alias dnsflush="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias kc='kubectl'
alias minikc="minikube kubectl --"
alias python='python3'

# Prompt

setopt PROMPT_SUBST

## virtualenv
virtual_env() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "($(basename "$VIRTUAL_ENV")) "
  fi
}

## kubernetes context
k8s_context() {
  if command -v kubectl >/dev/null; then
    local ctx
    ctx=$(kubectl config current-context 2>/dev/null)
    [[ -n "$ctx" ]] && echo "%F{magenta}[$ctx]%f "
  fi
}

## shortened path (like powerlevel10k)
short_path() {
  print -P "%~"
}

## git status
git_prompt() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  [[ -n "$branch" ]] && echo "($branch)"
}

## prompt
PS1='%F{cyan}$(virtual_env)%f$(k8s_context)%F{yellow}[%D{%H:%M:%S}]%f %F{blue}$(short_path)%f $(git_prompt) > '


# Functions

function dirdiff() {
  # Shell-escape each path:
  DIR1=$(printf '%q' "$1")
  shift
  DIR2=$(printf '%q' "$1")
  shift
  nvim "$@" -c "DirDiff $DIR1 $DIR2"
}

function awsr() {
  if [ $# -eq 1 ]; then
    export AWS_REGION="$1"
    export AWS_DEFAULT_REGION="$1"
    echo "AWS_REGION and AWS_DEFAULT_REGION set to $1"
  else
    echo "Usage: awsr <region>"
  fi
}

connect-ec2-db() {
  local region="$1"
  local name_filter="$2"

  if [[ -z "$region" || -z "$name_filter" ]]; then
    echo "Usage: connect-ec2-db <aws-region> <instance-name-contains>"
    return 1
  fi

  export AWS_REGION="$region"
  export AWS_DEFAULT_REGION="$region"

  echo "🔍 Fetching EC2 instances matching '$name_filter'..."
  local ec2_line=$(ec2-ssh --list | grep "$name_filter" | fzf --prompt="Select EC2 instance: ")

  if [[ -z "$ec2_line" ]]; then
    echo "❌ No EC2 instance selected."
    return 1
  fi

  local instance_id=$(echo "$ec2_line" | awk '{print $1}')

  echo "🔍 Fetching RDS instances..."
  local rds_line=$(aws rds describe-db-instances --query "DBInstances[*].[DBInstanceIdentifier,Endpoint.Address]" --output text | fzf --prompt="Select RDS instance: ")

  if [[ -z "$rds_line" ]]; then
    echo "❌ No RDS instance selected."
    return 1
  fi

  local rds_host=$(echo "$rds_line" | awk '{print $2}')

  echo "✅ Connecting to $instance_id and forwarding to $rds_host:5432..."

  ec2-ssh ec2-user@"$instance_id"  -L 65432:$rds_host:5432
}

