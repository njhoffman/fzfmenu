#!/bin/bash

FZF_CLEAR=${FZF_CLEAR:-1}

function main_menu_opts {
  opts="--ansi --print-query"
  opts="${opts} --preview-window='right:50%:wrap'"
  # if [[ -n $FZF_PREVIEW_CMD ]]; then
  #   opts="${opts} --preview='$FZF_PREVIEW_CMD'"
  # else
  pv_cmd="$SRC --preview {1} {q}"
  opts="${opts} --preview='$pv_cmd'"
  # fi

  # fzf_opts="--preview-window='nowrap'"
  opts="${opts} $(mode-prepare-options)"

  keys="enter,esc,ctrl-r,ctrl-\,ctrl-^"

  # [[ -n "$FZF_TOGGLES" ]] && expected_keys="${expected_keys},alt-1,alt-2,alt-3,alt-4,alt-5"
  opts="${opts} --expect='$keys'"

  if [ $FZF_CLEAR -eq 1 ]; then
    opts="${opts} --clear"
  else opts="${opts} --no-clear"; fi

  echo "${opts}"
}

function main_menu {
  opts="$(main_menu_opts)"

  # apply widgets own options if available
  if [[ $(type -t fzf_options 2>/dev/null) == 'function' ]]; then
    opts="${opts} $(fzf_options)"
  fi
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS ${opts}"
  # export FZF_DEFAULT_OPTS

  debug "opts: ${FZF_DEFAULT_OPTS}"
  # raw output without fzf
  if [[ $FZF_RAW_OUT -eq 1 ]]; then
    IFS=$'\n' result=($(eval "$FZF_DEFAULT_COMMAND"))
    printf "%s\n" "${result[@]}"
    exit 0
  fi

  if [[ $FZF_TMUX -eq 1 ]]; then
    IFS=$'\n' result=($(fzf-tmux $FZF_TMUX_OPTS))
  else
    IFS=$'\n' result=($(fzf))
  fi

  selected=()
  query=""
  if [[ ${#result[@]} -eq 3 ]]; then
    query="${result[0]}"
    key="${result[1]}"
    selected=($(echo "${result[*]:2}" | cut -f1 -d"${FZF_DELIMITER}"))
  else
    key="${result[0]}"
    selected=($(echo "${result[*]:1}" | cut -f1 -d"${FZF_DELIMITER}"))
  fi

  debug "main-menu key: $key"
  debug "$FZF_DEFAULT_OPTS"

  # determine if any mode changing keys were hit
  if [[ ${#FZF_MODES[@]} -gt 0 ]]; then
    mode-check-keys "$key"
  fi

  # if popout key pressed, toggle between fzf and fzf-tmux
  if [[ $key == 'ctrl-^' ]]; then
    if [[ $FZF_TMUX -eq 1 ]]; then
      FZF_TMUX=0
    else FZF_TMUX=1; fi
    menus+=(main_menu)

  # enter key pressed, run action or load another menu
  elif [[ $key == 'enter' ]]; then
    if [[ -n $FZF_DEFAULT_ACTION ]]; then
      debug "do the default action"
    else
      menus=(eval "action_menu ${selected[*]}")
    fi

  # exiting
  elif [[ $key == 'esc' ]]; then
    menus=()
  fi
}
