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
  case "$action" in
    'install')
      sudo apt install -qqq "${items[*]}"
      ;;
    'upgrade' | 'remove')
      echo "echo 'removing or upgrading ${items[*]}'"
      ;;
    *) fzf_result_default "$action" "${item_id}" ;;
  esac
  # done
}

function fzf_command {
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(fzf_options)"
  mode-display-hints
  if [[ $FZF_MODE -eq 1 ]]; then
    apt_search
  else
    apt_list
  fi
}

function fzf_preview() {
  mode_name="${FZF_MODES[$((FZF_MODE - 1))]}"
  selection="$1"
  case "$mode_name" in
    available | installed | upgradeable)
      yq eval '.Description-en' <(apt-cache show "$selection") 2>/dev/null \
        | bat --color always --plain
      apt-cache show $selection \
        | bat --language yaml --color always --plain
      ;;
  esac
}

function fzf_options {
  fzf_opts="--header-lines=1"
  echo "${fzf_opts}"
}

FZF_DEFAULT_COMMAND="$SRC --command"

source "../fzf.sh"
