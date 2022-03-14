#!/bin/bash

source "fzf.format.sh"
source "fzf.modes.sh"
function main-display {
  menus=(main_menu)
  menu_idx=1

  while [[ $menu_idx -gt 0 ]]; do
    menu_cnt="${#menus[@]}"
    eval ${menus[menu_idx - 1]}
    # eval "${menus[menu_idx - 1]}"
    if [[ $menu_cnt -lt ${#menus[@]} ]]; then
      menu_idx=$((menu_idx + 1))
    elif [[ ${#menus[@]} -eq 0 ]]; then
      menu_idx=0
    else
      menu_idx=$((menu_idx - 1))
    fi

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
    fzf_preview "${arg[@]}" "$@"
  elif [[ $arg == "--command" ]]; then
    shift && arg="${1:-}"
    fzf_command "$@"
  elif [[ $arg == "--command-mode" ]]; then
    shift && arg="${1:-}"
    FZF_MODE=$arg
    tmpfile_write
    fzf_command "$@"
  else
    tmpfile_write
    trap "tmpfile_cleanup" EXIT
    main-display "$*"
  fi
}

ARGV=($@)
for i in $(seq ${#ARGV[@]}); do
  j=$((i - 1))
  debug "arg${i}: ${ARGV[$j]}"
done

tmpfile_read
source "fzf.menu-action.sh"
source "fzf.menu-main.sh"

main "$@"
