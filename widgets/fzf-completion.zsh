if command -v fzf >/dev/null; then
  # # fuzzy completion with 'z' when called without args
  # unalias z 2> /dev/null
  # z() {
  #   [ $# -gt 0 ] && _z "$*" && return
  #   cd "$(_z -l 2>&1 | fzf --height 40% --nth 2.. --reverse --inline-info +s --tac --query "${*##-* }" | sed 's/^[0-9,.]* *//')"
  # }
  # Use fd (https://github.com/sharkdp/fd) instead of the default find
  # command for listing path candidates.
  # - The first argument to the function ($1) is the base path to start traversal
  # - See the source code (completion.{bash,zsh}) for the details.
  _fzf_compgen_path() {
    fd --hidden --follow --exclude ".git" . "$1"
  }

  # Use fd to generate the list for directory completion
  _fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" . "$1"
  }

__git_log () {
  # format str implies:
  #  --abbrev-commit
  #  --decorate
  git log \
    --color=always \
    --graph \
    --all \
    --date=short \
    --format="%C(bold blue)%h%C(reset) %C(green)%ad%C(reset) | %C(white)%s %C(red)[%an] %C(bold yellow)%d"
  }

_fzf_complete_git() {
  ARGS="$@"

  # these are commands I commonly call on commit hashes.
  # cp->cherry-pick, co->checkout

  if [[ $ARGS == 'git cp'* || \
    $ARGS == 'git cherry-pick'* || \
    $ARGS == 'git co'* || \
    $ARGS == 'git checkout'* || \
    $ARGS == 'git reset'* || \
    $ARGS == 'git show'* || \
    $ARGS == 'git log'* ]]; then
        _fzf_complete "--reverse --multi" "$@" < <(__git_log)
      else
        eval "zle ${fzf_default_completion:-expand-or-complete}"
  fi
}

_fzf_complete_git_post() {
  sed -e 's/^[^a-z0-9]*//' | awk '{print $1}'
}

_fzf_complete_ssh() {
  ARGS="$@"
  local machines
  machines=$(aws ec2 describe-instances \
    --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | \
    [0],Tags[?Key=='product'].Value | \
    [0], Tags[?Key=='environment'].Value | \
    [0], LaunchTime, PublicDnsName]" \
    --filters Name=instance-state-name,Values=running --output text | \
    tr ' ' '-' | \
    column -t -s $'\t')

  if [[ $ARGS == 'ssh '* ]]; then
    _fzf_complete "--reverse --multi" "$@" < <(
    echo $machines
  )
else
  eval "zle ${fzf_default_completion:-expand-or-complete}"
  fi
}

  _fzf_complete_ssh_post() {
    awk '{print $5}'
  }
# pass completion suggested by @d4ndo (#362) (slightly modified)
  _fzf_complete_pass() {
    _fzf_complete '+m' "$@" < <(
    local pwdir=${PASSWORD_STORE_DIR-~/.password-store/}
    find "$pwdir" -name "*.gpg" -print |
      sed -e "s#${pwdir}/\{0,1\}##" |
      sed -e 's/\(.*\)\.gpg/\1/'
    )
  }

  local f
  for f in $HOME/bin/fzf-rsc/completions/**/*.zsh(D); do
    source "$f"
  done
  # bindkey '^T' fzf-completion
  # bindkey '^I' fzf-tab-complete
  # export fzf_default_completion=expand-or-complete
  # export _fzf_tab_orig_widget=expand-or-complete

fi

#   if (( $+functions[_try_custom_completion] )); then
#      custom-fzf-tab-complete() { _try_custom_completion || fzf-tab-complete }
#      zle -N custom-fzf-tab-complete
#      bindkey '^I' custom-fzf-tab-complete
#    fi
#
