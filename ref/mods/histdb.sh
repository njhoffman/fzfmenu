#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SRC="${BASH_SOURCE[0]}"

FZF_MODES=('session' 'location' 'host' 'global')
FZF_MODES_HINT_KEYS=0
FZF_DEFAULT_MODE=3

FZF_TMUX_OPTS="-w100"

function fzf_results {
  action="$1" && shift
  items=($@)
  # echo "echo 'Performing $action on ${items[*]}'"
  for item in "${items[@]}"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    debug "$action: $item"
    case "$action" in
      *) fzf_result_default "$action" "${item}" ;;
    esac
  done
}

function fzf_command {
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(fzf_options)"
  mode_name="${FZF_MODES[$((FZF_MODE - 1))]}"
  case "$mode_name" in
    'session') opts="-s" ;;
    'location') opts="-d" ;;
    'host') opts="" ;;
    'global') opts="-t" ;;
  esac
  mode-display-hints
  # env HISTDB_PSESSION=$HISTDB_SESSION \
  ./histdb.zsh "${opts}"
}

function fzf_preview() {
  # mode="$1" && shift
  mode_name="${FZF_MODES[$((FZF_MODE - 1))]}"
  selection="$1"
  echo "selection:" "${selection[@]}"
}

function fzf_options {
  opts="\
  --header-lines=1
  --delimiter=' '
  --preview-window='hidden'
  --with-nth=2..
  --nth=2.."
  echo "${opts}"
}

FZF_DEFAULT_COMMAND="$SRC --command"
source "../fzf.sh"
