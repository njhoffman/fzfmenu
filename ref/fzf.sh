#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# SRC="${SRC:-${BASH_SOURCE[0]}}"
FZF_TMPDIR="${FZF_TMPDIR:-/tmp/fzf}"
FZF_TMUX=${FZF_TMUX:-0}
FZF_DEFAULT_COMMAND="${FZF_DEFAULT_COMMAND:-}"
FZF_TMUX_OPTS="${FZF_TMUX_OPTS:--p80%}"
FZF_RAW_OUT=${FZF_RAW_OUT:-0}
HEADER_LINES=${HEADER_LINES:-0}
export FZF_PID=${FZF_PID:-$PPID}

source "fzf.log.sh"
source "fzf.format.sh"

function tmpfile_read {
  pidfile="$FZF_TMPDIR/$FZF_PID.tmp"
  if [[ -f $pidfile ]]; then
    source "$pidfile"
  fi
}

function tmpfile_write {
  [[ ! -d $FZF_TMPDIR ]] && mkdir -p "$FZF_TMPDIR"
  pidfile="$FZF_TMPDIR/$FZF_PID.tmp"
  printf '#!/bin/bash\n' >"$pidfile"
  printf "FZF_MODE=$FZF_MODE \n" >>"$pidfile"
  printf "FZF_TMUX=$FZF_TMUX\n" >>"$pidfile"
}

function main_display {
  menus=(main_menu)
  menu_idx=1
  while [[ $menu_idx -gt 0 ]]; do
    menu_cnt="${#menus[@]}"
    debug "menu 1 :$menu_cnt $menu_idx"
    eval "${menus[menu_idx - 1]}"

    if [[ $menu_cnt -lt ${#menus[@]} ]]; then
      menu_idx=$((menu_idx + 1))
    elif [[ ${#menus[@]} -eq 0 ]]; then
      menu_idx=0
    else
      menu_idx=$((menu_idx - 1))
    fi
    debug "menu 2 :$menu_cnt $menu_idx"

  done
}

function tmpfile_cleanup {
  debug "cleaning up... $FZF_PID $FZF_TMPDIR/$FZF_PID.tmp"
  rm -f "$FZF_TMPDIR/$FZF_PID.tmp"
}

function main {
  arg="${1:-}"
  # flag to pipe output (list or preview) to stdout instead of fzf
  if [[ $arg == "--raw" ]]; then
    FZF_RAW_OUT=1
    shift && arg="${1:-}"
  fi

  # generate preview content
  if [[ $arg == "--preview" ]]; then
    shift && arg="${1:-}"
    fzf_preview "$arg"
  elif [[ $arg == "--command" ]]; then
    shift && arg="${1:-}"
    fzf_command "$*"
  elif [[ $arg == "--command-mode" ]]; then
    shift && arg="${1:-}"
    FZF_MODE=$arg
    tmpfile_write
    fzf_command "$*"
  else
    tmpfile_write
    trap "tmpfile_cleanup" EXIT
    main_display "$*"
  fi
}

tmpfile_read
source "fzf.menu-action.sh"
source "fzf.menu-main.sh"
main "$@"
