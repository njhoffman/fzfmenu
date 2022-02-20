#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

FZF_DEFAULT_ACTION="view"

FZF_ACTIONS=(
  "ssh"
)

FZF_ACTION_DESCRIPTIONS=(
  "SSH to target address"
)

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
}

# _fzf-extra-opts() {
#   opts="${opts} --nth=1,2,3,-1"
#   echo "$opts"
# }


_fzf-result() {
  action="$1" && shift
  items=($@)
  _fzf-log "${CMD} result $action (${#items[@]}): \n${items[@]}"

  for item in "$items[@]"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    case "$action" in
      'ssh')
          echo "ssh" $item_id
        ;;
    esac
  done
}

_fzf-prompt() {
  echo " avahi❯ "
}

_fzf-preview() {
  # echo "$2" | tr -d '()' \
  #   | awk '{printf "%s ", $2} {print $1}' \
  #   | xargs -r man \
  #   | col -bx \
  #   | bat --theme "$theme" -l man -p --color always
    # | tr -d '()'
    # | awk '{printf "%s ", $2} {print $1}'
}

_fzf-command() {
avahi-browse \
  --parsable \
  --all   \
  --resolve
  echo "${cmd}"
}

# _fzf-source
source "$FZF_LIB.zsh"
