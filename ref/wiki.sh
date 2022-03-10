#!/bin/bash

set -euo pipefail
IFS=$'\n\t'
SRC="${BASH_SOURCE[0]}"

declare -A clr
lc=$'\e[' rc=m
clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
clr[desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
clr[rst]="${lc}0${rc}"

FZF_MODES=('titles' 'tags' 'global')
FZF_MODE="${FZF_DEFAULT_MODE:-1}"

declare -A FZF_ACTIONS
FZF_ACTIONS[mdcat]="mdcat output"
FZF_ACTIONS[mdless]="mdless output"
FZF_ACTIONS[vimcat]="vimcat output"
FZF_ACTIONS[glow]="glow output"

FZF_ACTIONS_SORT=("mdcat" "mdless" "vimcat" "glow" "cat:id" "cat:preview" "yank:id" "yank:preview")

function wiki_titles {
  neuron='LC_ALL=C neuron -d ~/zettelkasten query --zettels'
  while IFS=$'\n' read -r line; do
    fields=".Title,.Path"
    IFS=$'\n' read -r -d '' title path \
      <<<$(echo "$line" | jq -r "$fields") || true
    printf "%s|%s\n" "$title" "$path"
  done <<<$(eval "$neuron" | jq -c '.[]') \
    | emojify \
    | column -s'|' -t \
    | cut -c -$(($(tput cols) - 1)) \
    || true
}

function wiki_tags {
  neuron='LC_ALL=C neuron -d ~/zettelkasten query --zettels'
  while IFS=$'\n' read -r line; do
    # fields=".ID,.Title,.Meta.tags[],.Date,.Path"
    fields=".ID,.Title,.Date,.Path,.Meta.tags[]"
    IFS=$'\n' read -r -d '' id title date path tags \
      <<<$(echo "$line" | jq -r "$fields") || true
    printf "%s|%s|%s|%s\n" "$id" "$title" "$date" "$path"
  done <<<$(eval "$neuron" | jq -c '.[]') \
    | column -s'|' -t \
    | cut -c -$(($(tput cols) - 1)) \
    || true
}

function wiki_global {
  echo -e "wiki global \nwiki global2"
}

function fzf_results {
  action="$1" && shift
  items=("$@")
  debug "results: $action ${#items[@]}"
  case "$action" in
    '*')
      debug "$action --- ${items[*]}"
      mdless "${items[@]}"
      ;;
  esac
  # done
}

function fzf_command {
  # display-mode-hints
  if [[ $FZF_MODE -eq 1 ]]; then
    wiki_titles
  elif [[ $FZF_MODE -eq 2 ]]; then
    wiki_tags
  else
    wiki_global
  fi
}

function fzf_preview() {
  # mode="$1" && shift
  mode=${FZF_MODE:-$FZF_DEFAULT_MODE}
  mode_name="${FZF_MODES[$((mode - 1))]}"
  selection="$*"
  case "$mode_name" in
    title | tags)
      mdless $selection
      ;;
    global)
      echo "global $selection"
      ;;
  esac
}

FZF_DEFAULT_COMMAND="$SRC --command"

source "fzf.sh"
