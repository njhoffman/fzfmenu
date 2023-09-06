#!/bin/bash

# TODO:
# https://github.com/junegunn/fzf/wiki/Related-projects
#   - figure out fifo pipes for multiple inputs
#   - separate _fzf-main or integrate fzf-menu description better
#   - unset variables
#   - verify functions and assignments
#   - make generic usage function that can be overridden
#   - if modes defined, assign with --mode name or --mode=name
#   - make shell clearing optional (transition screen in between fzf-menu switches)
#   - implement FZF_DEFAULT_ACTION instead of hardcoding copy_name
#   - determine if toggle_popout should stay on submenu
#   -  look into push to top instead of clear to preserve history
#
#   If fzf was started in full screen mode, it will not switch back to the original screen,
#   so you'll have to manually run tput rmcup to return

FZF_CLEAR=1
FZF_DIVIDER_SHOW=${FZF_DIVIDER_SHOW:-0}
FZF_DIVIDER_LINE="${FZF_DIVIDER_LINE:-―――――――――――――――――――――――――――}"
FZF_RAW_OUT=${FZF_RAW_OUT:-0}

FZF_DEFAULT_ACTION=${FZF_DEFAULT_ACTION:-""}

## action menu options: holds ids of items to perform action against
# echo:name:csv or echo/echo:csv
FZF_DEFAULT_ACTIONS=("echo:id" "echo:preview" "yank:id" "yank:preview")
FZF_DEFAULT_ACTION_DESCRIPTIONS=(
  "echo the item(s) first column"
  "echo what is displayed in preview pane for item(s)"
  "yank the item(s) first column to the clipboard"
  "yank the preview pane content for item(s) to the clipboard"
)

# combine default actions with any provided from module
if [[ -n $FZF_ACTIONS ]]; then
  FZF_ACTIONS=("${FZF_ACTIONS[@]}" "${FZF_DEFAULT_ACTIONS[@]}")
  FZF_ACTION_DESCRIPTIONS=("${FZF_ACTION_DESCRIPTIONS[@]}" "${FZF_DEFAULT_ACTION_DESCRIPTIONS[@]}")
else
  FZF_ACTION_DESCRIPTIONS=("${FZF_DEFAULT_ACTION_DESCRIPTIONS[@]}")
  FZF_ACTIONS=("${FZF_DEFAULT_ACTIONS[@]}")

fi

_fzf_tabularize() {
  if [[ $# == 0 ]]; then
    cat
    return
  fi

  awk \
    -v FS="${FS:- }" \
    -v colors_args="$*" \
    -v reset="\033[0m" '
  BEGIN { split(colors_args, colors, " ") }
  {
    str = $0
    for (i = 1; i <= length(colors); ++i) {
      field_max[i] = length($i) > field_max[i] ? length($i) : field_max[i]
      fields[NR, i] = $i
      pos = index(str, FS)
      str = substr(str, pos + 1)
    }
    if (pos != 0) {
      fields[NR, i] = str
    }
  }
  END {
    for (i = 1; i <= NR; ++i) {
      for (j = 1; j <= length(colors); ++j) {
        printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), colors[j], fields[i, j], reset
      }
      if ((i, j) in fields) {
        printf "  %s", fields[i, j]
      }
      printf "\n"
    }
  }
'
}

_fzf_tabularize_header() {
  if [[ $# == 0 ]]; then
    cat
    return
  fi
  header="$1"
  shift

  awk \
    -v FS="${FS:- }" \
    -v header="$header" \
    -v colors_args="$*" \
    -v reset="\033[0m" '
    BEGIN { split(colors_args, colors, " ") }
      {
        str = $0
        for (i = 1; i <= length(colors); ++i) {
          field_max[i] = length($i) > field_max[i] ? length($i) : field_max[i]
          fields[NR, i] = $i
          pos = index(str, FS)
          str = substr(str, pos + 1)
        }
        if (pos != 0) {
          fields[NR, i] = str
        }
      }
    END {
      for (i = 1; i <= NR; ++i) {
        for (j = 1; j <= length(colors); ++j) {
          if (i == 1) {
            printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), header, fields[i, j], reset
          } else {
          printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), colors[j], fields[i, j], reset
        }
      }
      printf "\n"
    }
  }
  '
}

# FZF_MODES: output of keys with highlighting to reflect active mode
_fzf-hints-modes() {
  local hide_keys=${FZF_MODES_HIDE_KEYS:-0}
  local hints=""
  local mode="$1"
  # calculate what the selected mode is
  for ((i = 1; i <= ${#FZF_MODES}; i++)); do
    label="${FZF_MODES[$i]}"
    [[ $hide_keys -eq 0 ]] && label="f${i}:${label}"
    if [[ ${FZF_MODES[i]} == "${FZF_MODES[mode]}" ]]; then
      hints="${hints}${_clr[mode_active]}${label}  ${_clr[rst]}"
    else
      hints="${hints}${_clr[mode_inactive]}${label}  ${_clr[rst]}"
    fi
  done
  echo "$hints"
}

# FZF_TOGGLES: output of keys with highlighting to reflect active toggles
_fzf-hints-toggles() {
  local hide_keys=${FZF_TOGGLES_HIDE_KEYS:-0}
  local hints=""
  toggle_vals="$1"
  # calculate what the selected mode is
  for ((i = 1; i <= ${#FZF_TOGGLES}; i++)); do
    label="${FZF_TOGGLES[i]}"
    clr_toggle="${_clr[toggle_active]}"
    toggle_val="$(echo "$toggle_vals" | cut -f"$i" -d' ')"
    _fzf-log "$i: $toggle_val"
    [[ $toggle_val -eq 0 ]] && clr_toggle="${_clr[toggle_inactive]}"
    [[ $hide_keys -eq 0 ]] && label="a${i}:${label}"
    hints="${hints}${clr_toggle}${label}  ${_clr[rst]}"
    # hints="${hints}${_clr[toggle_inactive]}${label}  ${_clr[rst]}"
  done
  echo "$hints"
}

# FZF_SORT: output of active sort key with highlighting
_fzf-hints-sort() {
  # 
  local hide_keys=${FZF_SORT_HIDE_KEYS:-0}
  local hints=""
  local sort_idx="$1"
  # calculate what the selected sort is
  for ((i = 1; i <= ${#FZF_SORT}; i++)); do
    label="${FZF_SORT[i]}"
    [[ $hide_keys -eq 0 ]] && label="f${i}:${label}"
    if [[ ${FZF_SORT[i]} == "${FZF_SORT[sort_idx]}" ]]; then
      hints="${hints}${_clr[sort_active]}${label}  ${_clr[rst]}"
    else
      hints="${hints}${_clr[sort_inactive]}${label}  ${_clr[rst]}"
    fi
  done
  echo "$hints"
}

# output usage information with switches based on FZF_ACTIONS, FZF_MODES, FZF_TOGGLES
_fzf-usage() {
  # Usage: tr [OPTION]... SET1 [SET2]
  # Translate, squeeze, and/or delete characters from standard input,
  # writing to standard output.

  echo "usage information"
  # With no FILE, or when FILE is -, read standard input.
  #       --mode=MODE         launch with assigned mode
  #                           MODE can be <as-needed|consistent|preserve>
  #   -b, --bytes=LIST        select only these bytes
  #   -c, -C, --complement    use the complement of SET1
  #   -d, --delete            delete characters in SET1, do not translate
  #   -s, --squeeze-repeats   replace each sequence of a repeated character
  #                           that is listed in the last specified SET,
  #                           with a single occurrence of that character
  #   -t, --truncate-set1     first truncate SET1 to length of SET2
  #       --help              display this help and exit
  #       --version           output version information and exit
}

_fzf-unset() {
  unset -f _fzf-actions-source-default 2> /dev/null &&
    unset -f _fzf-assign-vars 2> /dev/null &&
    unset -f _fzf-assign-vars-default 2> /dev/null &&
    unset -f _fzf-display 2> /dev/null &&
    unset -f _fzf-log 2> /dev/null &&
    unset -f _fzf-header 2> /dev/null &&
    unset -f _fzf-main 2> /dev/null &&
    unset -f _fzf-mode-hints 2> /dev/null &&
    unset -f _fzf-preview 2> /dev/null &&
    unset -f _fzf-prompt 2> /dev/null &&
    unset -f _fzf-result-default 2> /dev/null &&
    unset -f _fzf-source 2> /dev/null &&
    unset -f _fzf-verify 2> /dev/null &&
    unset -v "$FZF_MODES" 2> /dev/null &&
    unset -v "$FZF_DEFAULT_MODE" 2> /dev/null &&
    unset -v "$FZF_ACTIONS" 2> /dev/null &&
    unset -v "$FZF_DESCRIPIONS" 2> /dev/null &&
    unset -v "$FZF_LOGFILE" 2> /dev/null &&
    unset -v _clr 2> /dev/null &&
    unset -v _fzf_log_first 2> /dev/null
}
