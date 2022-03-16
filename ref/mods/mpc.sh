#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SRC="${BASH_SOURCE[0]}"

FZF_MODES=('queue' 'playlists' 'library')
# media library: artists -> albums -> songs

FZF_MODE="${FZF_DEFAULT_MODE:-1}"
FZF_MODE_ROUNDED=${FZF_MODE_ROUNDED:-1}

declare -A FZF_ACTIONS
FZF_ACTIONS[play]="play song"
FZF_ACTIONS[next]="next song"
FZF_ACTIONS[prev]="prev song"

FZF_ACTIONS_SORT=(
  "play"
  "next"
  "prev"
  "cat:id"
  "cat:preview"
  "yank:id"
  "yank:preview"
)

function fzf_results {
  action="$1" && shift
  items=($@)
  # echo "echo 'Performing $action on ${items[*]}'"
  for item in "${items[@]}"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    debug "$action: $item"
    case "$action" in
      'play') echo "play ${item}" ;;
      'next') echo "next ${item}" ;;
      'prev') echo "prev ${item}" ;;
      *) fzf_result_default "$action" "${item}" ;;
    esac
  done
}

function fzf_command {
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(fzf_options)"
  mode-display-hints
  if [[ $FZF_MODE -eq 1 ]]; then
    mpc playlist # -f %file%
  elif [[ $FZF_MODE -eq 2 ]]; then
    mpc lsplaylist # -f %file%s
  else
    mpc listall # -f %file%
  fi
}

function fzf_preview() {
  # mode="$1" && shift
  mode_name="${FZF_MODES[$((FZF_MODE - 1))]}"
  selection="$1"
  echo "selection:" "${selection[@]}"
}

function fzf_options {
  opts="\
  --preview-window='hidden:nowrap'"
  echo "${opts}"
}

FZF_DEFAULT_COMMAND="$SRC --command"
source "../fzf.sh"
