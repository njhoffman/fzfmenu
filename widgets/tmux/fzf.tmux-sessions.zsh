#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"
RAW=0
TARGET_DIR="${1:-$HOME/git}"

function usage() {
  echo "Usage ..."
}

# output list of directory names with special handling
# for sessions existing or defined in TMUXP_DIR
function _fzf-command() {
  cmd="tmux-list-sessions $TARGET_DIR"
  echo "${cmd}"
}


_fzf-extra-opts() {
  if [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ]; then
    opts=""
  else
    opts="--height 70%"
  fi
  echo "$opts"
}

_fzf-result() {
  action="$1" && shift
  items=($@)

  if [[ "$action" == "echo:id" ]]; then
    # need full line for directory info
    # printf "%s\n" ${item_ids[@]}
    printf "%s\n" "${items[@]}"
    exit 0
  elif [[ "$action" == "yank:id" ]]; then
    item_ids=($(printf "%s\n" ${items[@]} | sed 's/ \+/\t/g' | cut -f2))
    printf "%s\n" ${items_ids[@]} | xsel --clipboard
    echo "Copied ${#items[@]} item names to clipboard"
    exit 0
  fi
}

_fzf-prompt() {
  echo " sessions❯ "
}

_fzf-preview() {
  echo "These are my preview pids: $*"
}

# if [[ $RAW -eq 1 ]]; then
#   printf "$(_fzf-source)" | column -s'\|' -t
#   exit 0
# fi

# display_dir="${TARGET_DIR/$HOME/\~}"
# fzf_cmd="fzf"

# fzf_opts="${fzf_opts} --query='${query}'"

if [[ $# -gt 0 ]]; then
  if [[ ! -d "$1" ]]; then
    echo "Directory not found: $1 - using default $TARGET_DIR"
  else
    TARGET_DIR="$1"
  fi
fi

source "${FZF_LIB}.zsh"
