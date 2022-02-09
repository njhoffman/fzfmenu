#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"
RAW=0

function usage() {
  echo "Usage ..."
}

if [[ $# -gt 0 ]]; then
  if [[ ! -d "$1" ]]; then
    echo "Directory not found: $1 - using default $TARGET_DIR"
  else
    TARGET_DIR="$1"
  fi
fi

# output list of directory names with special handling
# for sessions existing or defined in TMUXP_DIR
function _fzf-command() {
  cmd="tmux-list-sessions"
  echo "${cmd}"
}


_fzf-extra-opts() {
  # opts="--query=\"!fzf $*\""
  # opts="${opts} --nth=1,2,3,-1"
  # opts="${opts} --tac"
  # opts="${opts} --header-lines=1"
  # [ $RELOAD_ON_CHANGE -eq 1 ] && \
  #   opts="${opts},change:reload:'$source_command'"
  echo "$opts"
}

_fzf-result() {
  action="$1" && shift
  items=($@)
  item_ids=($(printf "%s\n" ${items[@]} | sed 's/ \+/\t/g' | cut -f2))

  if [[ "$action" == "echo:id" ]]; then
    printf "%s\n" ${item_ids[@]}
    exit 0
  elif [[ "$action" == "yank:id" ]]; then
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

source "${FZF_LIB}.zsh"
