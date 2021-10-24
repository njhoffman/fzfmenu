#!/bin/zsh

SOURCE="${(%):-%N}"
cwd="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
fzf_lib="$cwd/../fzf-lib.zsh"

# required - return formatted list
_fzf-source() {
  mode="$1" && shift
  selection="$*"
  case "$mode" in esac
}

# required - what to do with the selection
_fzf-result() {
  mode="$1" && shift
  selection="echo $* | cut -d' ' -f1"
  case "$mode" in esac
}

# optional - initialize variables that can be overridden by environment variables
_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  # _clr[name]="${lc}${CLR_ID:-38;5;30}${rc}"
}

# optional - what to show for prompt option
_fzf-prompt() {
  echo "apt❯ "
}

# optional - what to show for the top header line
_fzf-header() {
  mode="$1"
  case "$mode" in
    '*') echo "${_clr[name]}Remove installed apt package${_clr[rst]}" ;;
  esac
}

# optional - what to display of selected in preview window
_fzf-preview() {
  mode="$1"
  shift
  selection="$*"
  case "$mode" in esac
}

# optional - show custom usage/help information
_fzf-usage() {}

# optional - different mode names (one active at a time)
FZF_MODES=('install' 'remove')
#FZF_MODES_KEYS=('F1', 'F2')

# optional - different toggle names (each can be on/off)
FZF_TOGGLES=('user' 'system')
#FZF_TOGGLES_KEYS=('S-F1', 'S-F2')

# optional - different actions each on selected
FZF_ACTIONS=('copy id' 'pop-out')
#FZF_ACTIONS_KEYS=('C-e', 'C-^')

source "$fzf_lib"
