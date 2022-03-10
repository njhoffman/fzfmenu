#!/bin/bash

FZF_CLEAR=${FZF_CLEAR:-1}

if [[ -n $FZF_MODES ]]; then
  lc=$'\e[' rc=m rst="${lc}0${rc}"
  FZF_DEFAULT_MODE="${FZF_DEFAULT_MODE:-1}"
  FZF_DEFAULT_ACTION="${FZF_DEFAULT_ACTION:-}"
  FZF_MODE="${FZF_MODE:-$FZF_DEFAULT_MODE}"

  declare -A FZF_MODE_OPT
  FZF_MODE_OPT[immediate]=${FZF_MODE_IMMEDIATE:-1}
  FZF_MODE_OPT[hints]=${FZF_MODE_HINTS:-1}
  FZF_MODE_OPT[hint_keys]=${FZF_MODE_HINT_KEYS:-0}
  FZF_MODE_OPT[space_even]=${FZF_MODE_SPACE_EVEN:-0}
  FZF_MODE_OPT[rounded]=${FZF_MODE_ROUNDED:-0}
  FZF_MODE_OPT[clr_active]="${lc}${CLR_MODE_ACTIVE:-38;5;45;1}${rc}"
  FZF_MODE_OPT[clr_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;240}${rc}"

  if [[ ${FZF_MODE_OPT[hints]} -eq 1 ]]; then
    HEADER_LINES=$(( HEADER_LINES + 1 ))
  fi
fi


function display-mode-hints {
  local hints=""
  for ((i = 0; i <= ${#FZF_MODES}; i++)); do
    FZF_MODES[i]=${FZF_MODES[i]:-}
    label="${FZF_MODES[i]}"
    [[ ${FZF_MODE_OPT[hint_keys]} -eq 1 ]] \
      && label="f${i}:${label}"

    if [[ "${FZF_MODES[i]}" == "${FZF_MODES[$(( FZF_MODE - 1 ))]}" ]]; then
      hints="${hints}${FZF_MODE_OPT[clr_active]}${label}  ${rst}"
    else
      hints="${hints}${FZF_MODE_OPT[clr_inactive]}${label}  ${rst}"
    fi
  done
  echo "${hints}"
}

function main_menu_opts {
  fzf_opts="--ansi --print-query"
  fzf_opts="${fzf_opts} --header-lines=$HEADER_LINES"
  fzf_opts="${fzf_opts} --preview-window='right:50%:wrap'"
  # fzf_opts="${fzf_opts} --preview='$SRC --preview $FZF_PID {1}'"
  fzf_opts="${fzf_opts} --preview='$SRC --preview {1}'"

  keys="enter,esc,ctrl-r,ctrl-],ctrl-\,ctrl-^"
  if [[ -n $FZF_MODES ]]; then
    keys="${keys},alt-0,alt-9"
    if [[ ${FZF_MODE_OPT[immediate]} -eq 1 ]]; then
      for i in "${!FZF_MODES[@]}"; do
        fzf_opts="${fzf_opts} --bind 'f$((i + 1)):reload($SRC --command-mode $((i + 1)))'"
      done
    else
      for i in "${!FZF_MODES[@]}"; do
        keys="${keys},f${i}"
      done
    fi
  fi

  # [[ -n "$FZF_TOGGLES" ]] && expected_keys="${expected_keys},alt-1,alt-2,alt-3,alt-4,alt-5"

  fzf_opts="${fzf_opts} --expect='$keys'"

  if [ $FZF_CLEAR -eq 1 ]; then
    fzf_opts="${fzf_opts} --clear"
  else fzf_opts="${fzf_opts} --no-clear"; fi
  echo "$fzf_opts"
}

function check_key_modes {
  key="$1"
  if [[ $key =~ f. ]]; then
    FZF_MODE=${key#f}
  elif [[ $key == "alt-9" ]]; then
    if [[ $FZF_MODE -eq 1 ]]; then
      FZF_MODE=$((${#FZF_MODES[@]}))
    else
      FZF_MODE=$((FZF_MODE - 1 % ${#FZF_MODES[@]}))
    fi
  elif [[ $key == "alt-0" || $key == "ctrl-]" ]]; then
    FZF_MODE=$(((FZF_MODE % ${#FZF_MODES[@]}) + 1))
  fi
}

function main_menu {
  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(main_menu_opts)"

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
  if [[ ${#result[@]} -eq 3 ]]; then
    query="${result[0]}"
    key="${result[1]}"
    # selected=(${result[@]:2})
    selected=($(echo "${result[*]:2}" | cut -f1 -d' '))
  else
    query=""
    key="${result[0]}"
    selected=($(echo "${result[*]:1}" | cut -f1 -d' '))
  fi

  if [[ ${#FZF_MODES[@]} -gt 0 ]]; then
    check_key_modes $key
  fi

  # if popout key pressed, toggle between fzf and fzf-tmux
  if [[ $key == 'ctrl-^' ]]; then
    if [[ $FZF_TMUX -eq 1 ]]; then
      FZF_TMUX=0
    else FZF_TMUX=1; fi
    menus+=(main_menu)
  elif [[ $key == 'enter' ]]; then
    if [[ -n $FZF_DEFAULT_ACTION ]]; then
      debug "do the default action"
    else
      debug "adding action menu ${#selected[@]}"
      debug "${selected[@]}"
      menus=("$(action_menu ${selected[*]})")
    fi
  elif [[ $key == 'esc' ]]; then
    menus=()
  fi
}
