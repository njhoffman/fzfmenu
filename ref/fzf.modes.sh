#!/bin/bash

declare -A FZF_UI_OPTS
lc=$'\e[' rc=m
FZF_UI_OPTS[mode_inplace]=${FZF_MODE_INPLACE:-1}
FZF_UI_OPTS[mode_hints]=${FZF_MODE_HINTS:-1}
FZF_UI_OPTS[mode_hint_keys]=${FZF_MODE_HINT_KEYS:-0}
FZF_UI_OPTS[mode_space_even]=${FZF_MODE_SPACE_EVEN:-0}
FZF_UI_OPTS[mode_rounded]=${FZF_MODE_ROUNDED:-0}
FZF_UI_OPTS[mode_clr_active]="${lc}${CLR_MODE_ACTIVE:-38;5;45;1}${rc}"
FZF_UI_OPTS[mode_clr_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;240}${rc}"

FZF_MODES=(${FZF_MODES[@]:-})
FZF_DEFAULT_MODE="${FZF_DEFAULT_MODE:-1}"
FZF_MODE="${FZF_MODE:-$FZF_DEFAULT_MODE}"
FZF_DEFAULT_ACTION="${FZF_DEFAULT_ACTION:-}"

function mode-check-keys {
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

function mode-display-hints {
  hints=""
  for ((i = 0; i < ${#FZF_MODES[@]}; i++)); do
    mode_name=${FZF_MODES[i]:-}
    label="$mode_name"

    [[ ${FZF_UI_OPTS[mode_hint_keys]} -eq 1 ]] \
      && label="f${i}:${mode_name}"

    [[ ${FZF_UI_OPTS[mode_rounded]} -eq 1 ]] \
      && label="(${label})"

    curr=${FZF_MODES[$((FZF_MODE - 1))]}
    if [[ $mode_name == "$curr" ]]; then
      hints="${hints}${FZF_UI_OPTS[mode_clr_active]}${label}  ${rst}"
    else
      hints="${hints}${FZF_UI_OPTS[mode_clr_inactive]}${label}  ${rst}"
    fi
  done
  printf " %s\n" "${hints}"
}

function mode-prepare-options {
  if [[ ${#FZF_MODES[@]} -eq 0 ]]; then return 0; fi
  opts=""
  # load menus within same shell by triggering reload events
  for i in "${!FZF_MODES[@]}"; do
    mode_bind="f$((i + 1)):reload($SRC --command-mode $((i + 1)))"
    opts="${opts} --bind '${mode_bind}'"
  done
  echo "${opts}"
}

function mode-get-name {
  mode="${1:1}"
  mode_name="${FZF_MODES[$((mode - 1))]}"
  echo "$mode_name"
}
