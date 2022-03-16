#!/bin/bash

FZF_CLEAR=${FZF_CLEAR:-1}

function main_menu_opts {
  pv_cmd="$SRC --preview {1} {q}"
  opts="\
  --ansi
  --multi
  --header-lines=0
  --preview-window='right:50%:wrap'
  --preview='$pv_cmd'
  --print-query"

  # fzf_opts="--preview-window='nowrap'"
  mode_opts="$(mode-prepare-options)"
  opts="${opts} ${mode_opts}"

  keys="enter,esc,ctrl-^"

  # [[ -n "$FZF_TOGGLES" ]] && expected_keys="${expected_keys},alt-1,alt-2,alt-3,alt-4,alt-5"
  opts="${opts} --expect='$keys'"

  if [ $FZF_CLEAR -eq 1 ]; then
    opts="${opts}
  --clear"
  else
    opts="${opts}
  --no-clear"
  fi

  echo "${opts}"
}

function main_menu_results {
  pfx="\033[38;5;38mmain:\033[0m"
  selected=()
  query=" "
  res=($@)
  if [[ ${res[0]} == 'enter' || ${res[0]} == 'esc' || ${res[0]} == 'ctrl-^' ]]; then
    key="${res[0]}"
    selected=($(echo "${res[*]:1}" | cut -f1 -d"${FZF_DELIMITER}"))
  else
    query="${res[0]}"
    key="${res[1]}"
    selected=($(echo "${res[*]:2}" | cut -f1 -d"${FZF_DELIMITER}"))
  fi
  debug "$pfx key      : $key" "$pfx query    : $query"
  debug "$pfx selected: ${#selected[@]}" "${selected[@]}"
  printf "%s\n%s\n" "$query" "$key"
  printf "%s\n" "${selected[@]}"
}

function main_menu {
  pfx="\033[38;5;38mmain:\033[0m"

  opts="$(main_menu_opts)"

  # apply widgets own options if available
  if [[ $(type -t fzf_options 2>/dev/null) == 'function' ]]; then
    opts="${opts} $(fzf_options)"
  fi

  debug "$pfx\n${opts}"

  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS ${opts}"

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

  results=($(main_menu_results "${result[@]}"))
  query=${results[0]}
  key=${results[1]}
  selected=(${results[*]:2})

  # debug "$pfx key      : $key" "$pfx query    : $query"
  # debug "$pfx selected: ${#selected[@]}"
  # debug "${selected[@]}"

  # determine if any mode changing keys were hit
  if [[ ${#FZF_MODES[@]} -gt 0 ]]; then
    mode-check-keys "$key"
  fi

  # if popout key pressed, toggle between fzf and fzf-tmux
  if [[ $key == 'ctrl-^' ]]; then
    if [[ $FZF_TMUX -eq 1 ]]; then
      FZF_TMUX=0
    else FZF_TMUX=1; fi
    menus+=('main_menu')

  # enter key pressed, run action or load another menu
  elif [[ $key == 'enter' ]]; then
    if [[ -n $FZF_DEFAULT_ACTION ]]; then
      debug "$pfx do the default action"
    else
      menus=(eval "action_menu ${selected[*]}")
    fi

  # exiting
  elif [[ $key == 'esc' ]]; then
    menus=()
  fi
}
