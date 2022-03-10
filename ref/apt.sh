#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
SRC="${BASH_SOURCE[0]}"

declare -A clr
lc=$'\e[' rc=m
clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
clr[desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
clr[rst]="${lc}0${rc}"

FZF_MODES=('available' 'installed' 'upgradeable')
FZF_MODE="${FZF_DEFAULT_MODE:-1}"

declare -A FZF_ACTIONS
FZF_ACTIONS[install]="install package"
FZF_ACTIONS[upgrade]="upgrade package"
FZF_ACTIONS[remove]="remove package"
FZF_ACTIONS_SORT=("install" "upgrade" "remove" "cat:id" "cat:preview" "yank:id" "yank:preview")


function apt_search {
  apt-cache search '.*' \
    | sort \
    | sed -u -r \
      "s/^([^ ]+)(.*)/${clr[id]}\1${clr[desc]}\2${clr[rst]}/"
}

function apt_list {
  apt list --installed 2>/dev/null \
    | sort \
    | sed -u -r \
      "s/^([^ ]+)(.*)/${clr[id]}\1${clr[desc]}\2${clr[rst]}/"
}

function fzf_results {
  action="$1" && shift
  items=($@)
  debug "results: $action ${#items[@]}"
  # for item in "${items[@]}"; do
  # item_id=$(echo "$item" | cut -d' ' -f1)
  # debug "$action - $items"
  # 2ping 0ad-data 0ad-data-common
  case "$action" in
    'install')
      debug "install --- ${items[*]}"
      sudo apt install -qqq "${items[@]}"
      ;;
    'upgrade'|'remove')
      debug "upgrade or remove ${items[*]}"
      ;;
    *)
      debug "doing default: $action - $item_id"
      fzf_result_default "$action" "${item_id}"
      ;;
  esac
  # done
}

function fzf_command {
  display-mode-hints
  if [[ $FZF_MODE -eq 1 ]]; then
    apt_search
  else
    apt_list
  fi
}

function fzf_preview() {
  # mode="$1" && shift
  mode=${FZF_MODE:-$FZF_DEFAULT_MODE}
  mode_name="${FZF_MODES[$(( mode - 1 ))]}"
  selection="$*"
  case "$mode_name" in
    available)
      yq eval '.Description-en' <(apt-cache show "$selection") 2>/dev/null \
        | bat --color always --plain
      apt-cache show $selection \
        | bat --language yaml --color always --plain
      ;;
    installed)
      echo "installed $selection"
      ;;
    upgradeable)
      echo "upgradeable $selection"
      ;;
  esac
}

FZF_DEFAULT_COMMAND="$SRC --command"

source "fzf.sh"
