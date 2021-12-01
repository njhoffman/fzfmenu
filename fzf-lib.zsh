#!/bin/zsh

# TODO:
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



FZF_LOGFILE="/tmp/fzf.log"
setopt localoptions noglobsubst noposixbuiltins pipefail 2>> ${FZF_LOGFILE:-/dev/null}

FZF_CLEAR=1
FZF_DIVIDER_SHOW=${FZF_DIVIDER_SHOW:-0}
FZF_DIVIDER_LINE="${FZF_DIVIDER_LINE:-―――――――――――――――――――――――――――}"
FZF_RAW_OUT=0

## action menu options: holds ids of items to perform action against
# echo:name:csv or echo/echo:csv
FZF_DEFAULT_ACTIONS=("echo" "echo:preview" "yank" "yank:preview")
FZF_DEFAULT_ACTION_DESCRIPTIONS=(
  "echo the item(s) first column"
  "echo what is displayed in preview pane for item(s)"
  "yank the item(s) first column to the clipboard"
  "yank the preview pane content for item(s) to the clipboard"
)

# combine default actions with any provided from module
if [[ -n "$FZF_ACTIONS" ]]; then
  FZF_ACTIONS=("${FZF_ACTIONS[@]}" "${FZF_DEFAULT_ACTIONS[@]}")
  FZF_ACTION_DESCRIPTIONS=("${FZF_ACTION_DESCRIPTIONS[@]}" "${FZF_DEFAULT_ACTION_DESCRIPTIONS[@]}")
else
  FZF_ACTION_DESCRIPTIONS=("${FZF_DEFAULT_ACTION_DESCRIPTIONS[@]}")
  FZF_ACTIONS=("${FZF_DEFAULT_ACTIONS[@]}")

fi

declare -A _clr
declare -A _fzf_keys

if [[ ! -z ${FZF_LOGFILE} ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

# signal logger to output file header
_fzf_log_first=0
_fzf-log() {
  if [[ ! -z ${FZF_LOGFILE} ]]; then
    [[ _fzf_log_first -eq 0 ]] && \
      printf "--------------------\n${SOURCE}\n" >> ${FZF_LOGFILE}
    echo -e "\n$*" >> ${FZF_LOGFILE} && _fzf_log_first=1
  fi
}

_fzf-verify() {
  # ensure functions exist: _fzf-source, _fzf-result
}

# assigns default colors keys that can be overridden by each module
_fzf-assign-default-vars() {
  local lc=$'\e[' rc=m
  _clr[mode_active]="${lc}${CLR_MODE_ACTIVE:-38;5;117}${rc}"
  _clr[mode_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;68}${rc}"
  _clr[divider]="${lc}${CLR_DIVIDER:-38;5;59}${rc}"
  _clr[action_id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[action_desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
  # TODO: implement this into preview window as well
  # _clr[action_header]=""
  # _clr[action_target]=""
  _clr[rst]="${lc}0${rc}"

  _fzf_keys[toggle_popout]="ctrl-^"
  _fzf_keys[reload]="ctrl-r"
  _fzf_keys[mode_prev]="alt-9"
  _fzf_keys[mode_next]="alt-0"
  # _fzf_keys[actions_menu]="ctrl-\\"
  # _fzf_keys[actions_menu]="ctrl-space"
  _fzf_keys[actions_menu]='ctrl-\'
  _fzf_keys[help_menu]=""
  _fzf_keys[exit]="esc"
}


# FZF_ACTIONS: output the "action menu" if defined by if _fzf_kekys[action_menu] pressed
_fzf-default-actions-source() {
  lines=()
  for ((i=1; i<=${#FZF_ACTIONS}; i++)); do
    id="$FZF_ACTIONS[$i]"
    desc="$FZF_ACTION_DESCRIPTIONS[$i]"
    lineout="${_clr[rst]}${_clr[action_id]}${id}"
    lineout="${lineout}|${_clr[action_desc]}${desc}"
    lineout="${lineout}|${cmd}${_clr[rst]}"
    lines+=( "$lineout" )
  done
  printf '%s\n' "${lines[@]}" | column -t -s'|'
}


# default action menu handlers (can be overridden or silenced by modules)
_fzf-handle-result() {
  # _fzf-log "handle result lines: $* \n--"
  action="$1" && shift
  items=($@)
  item_ids=($(printf "%s\n" ${items[@]} | cut -d' ' -f1))

  if [[ "$action" == "echo" ]]; then
    printf "%s\n" ${item_ids[@]}
  elif [[ "$action" == "echo:preview" ]]; then
    echo "Preview ${#items[@]} item names"
  elif [[ "$action" == "yank" ]]; then
    printf "%s\n" ${items_ids[@]} | xsel --clipboard
    echo "Copied ${#items[@]} item names to clipboard"
  elif [[ "$action" == "yank:preview" ]]; then
    echo "${#items[@]} to preview" | xsel --clipboard
    echo "Copied ${#items[@]} preview items to clipboard "
  else
    _fzf-result $action $items
  fi
}


# FZF_MODES: output of keys with highlighting to reflect active mode
_fzf-mode-hints() {
  local hints=""
  local mode="$1"
  # calculate what the selected mode is
  for ((i=1; i<=${#FZF_MODES}; i++)); do
    if [[ "${FZF_MODES[i]}" == "${FZF_MODES[mode]}" ]]; then
      hints="${hints}${_clr[mode_active]}F${i}: ${FZF_MODES[i]}  ${_clr[rst]}"
    else
      hints="${hints}${_clr[mode_inactive]}F${i}: ${FZF_MODES[i]}  ${_clr[rst]}"
    fi
  done
  echo "${hints}"
}


# output usage information with switches based on FZF_ACTIONS, FZF_MODES, FZF_TOGGLES
_fzf-usage() {
  # Usage: tr [OPTION]... SET1 [SET2]
  # Translate, squeeze, and/or delete characters from standard input,
  # writing to standard output.

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

# main display loop for fzf until exit key is pressed or action is finished
_fzf-display() {
  local selected
  local num
  local mode
  local exitkey
  local typ
  local cmd_opts
  local fzf_cmd_args
  local action_menu=()

  ORIG_FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS
  query="$*"

  # use fzf-tmux if inside TMUX and FZF_TMUX is set
  local fzf_cmd="fzf"
  if [ -n "$TMUX_PANE" ] && \
    { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ] }; then
    fzf_cmd="fzf-tmux"
    fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
  fi

  if [[ -n ${FZF_DEFAULT_MODE} ]]; then
    mode=${FZF_DEFAULT_MODE}
  else
    mode=1
  fi

  exitkey=$_fzf_keys[reload]

  # TODO: turn mode into FZF_MODE, try to break this up
  while [[ "$exitkey" != "" && "$exitkey" != ${_fzf_keys[exit]} && "$exitkey" != "enter" ]]; do
    fzf_opts=""
    query=""
    header=""
    _fzf_log_first=0

    # if popout key pressed, toggle between fzf and fzf-tmux
    if [[ $exitkey == $_fzf_keys[toggle_popout] ]]; then
      if [[ $fzf_cmd == "fzf-tmux" ]]; then
        fzf_cmd="fzf"
        fzf_cmd_args=""
      else
        fzf_cmd="fzf-tmux"
        fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
      fi
    fi

    # show actions submenu
    if [ ${#action_menu[@]} -gt 0 ]; then
      # fzf_opts="--header-first"
      fzf_opts="--no-multi --print-query --preview-window=:hidden"
      if [ ${#action_menu[@]} -gt 1 ]; then
        header="Perform action on ${#action_menu[@]} items"
      else
        header="Perform action on: $(cut -d' ' -f1 <<<${action_menu[1]})"
      fi

      [[ -n "$header" ]] && fzf_opts="${fzf_opts} --header='${header}'"

      [[ "$(command -V _fzf-prompt)" =~ "function" ]] && \
        fzf_opts="${fzf_opts} --prompt='$(_fzf-prompt $mode)'"

      expected_keys="enter,${_fzf_keys[exit]},${_fzf_keys[reload]},${_fzf_keys[toggle_popout]}"
      expected_keys="${expected_keys},${_fzf_keys[actions_menu]}"
      fzf_opts="${fzf_opts} --expect='$expected_keys'"

      FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

      # only output the text without piping to fzf
      if [[ $FZF_RAW_OUT -eq 1 ]]; then
        IFS=$'\n' result=($(_fzf-default-actions-source $mode))
        printf "%s\n" "${result[@]}" | column -t
        exit 0
      fi

      # actually perform fzf command here
      IFS=$'\n' result=($(_fzf-default-actions-source $mode | $fzf_cmd $fzf_cmd_args ))

      # determine if query was submitted by identifying line exit key is on
      if [[ ${#result[@]} -gt 2 && $expected_keys =~ ${result[2]} ]]; then
        query="$(echo ${result[1]} | xargs)"
        exitkey="$(echo ${result[2]} | xargs)"
        selected_action="$(cut -d' ' -f1 <<<${result[@]:2})"
      else
        query=""
        exitkey="$(echo ${result[1]} | xargs)"
        selected_action="$(cut -d' ' -f1 <<<${result[@]:1})"
      fi

      local log_lines=()
      local lines=$(_fzf-default-actions-source $mode | head -n 5)
      [[ -n "$query" ]] && log_lines+=("query:\t${query}")
      [[ -n "$exitkey" ]] && log_lines+=("exit-key:\t${exitkey}")
      [[ -n "$selected_action" ]] && log_lines+=("select-action:\t${selected_action}")
      _fzf-log "actions menu top 5: \n${lines[@]}\n-\n${log_lines[@]}"

      # perform action (selected) on item(s) (action_menu) if enter or back to previous menu
      if [[ "$exitkey" == "enter" ]]; then
        _fzf-handle-result "$selected_action" "${action_menu[@]}"
        _fzf-log "_fzf-handle-result - $selected_action (${#action_menu[@]} items)"
      else
        action_menu=""
        exitkey="${_fzf_keys[reload]}"
      fi

    # show main list menu
    else

      # if modes defined and key pressed was a function key or a mode-left / mode-right key
      if [[ ${#FZF_MODES[@]} -gt 0 ]]; then
        if [[ $exitkey =~ "f." ]]; then
          mode=${exitkey[$(($MBEGIN+1)),$MEND]}
        elif [[ "$exitkey" == $_fzf_keys[mode_prev] ]]; then
          if [[ $mode -eq 1 ]]; then
            mode=$(($#FZF_MODES))
          else
            mode=$((($mode-1 % $#FZF_MODES)))
          fi
        elif [[ "$exitkey" == $_fzf_keys[mode_next] ]]; then
          mode=$((($mode % $#FZF_MODES) + 1))
        fi

        # optional function to customize widget props based on mode
        [[ "$(command -V _fzf-assign-mode)" =~ "function" ]] \
          && _fzf-assign-mode $mode
      fi

      # render header lines
      if [[ "$(command -V _fzf-header)" =~ "function" ]]; then
         header="$(_fzf-header $mode)"
      else
        hints=$(_fzf-mode-hints $mode)
        [[ -n "$hints" ]] && _fzf-log "hints:\t${hints}"
        header="${hints:-}"
      fi

      # TODO: any other way to embed hard line break?
      [[ $FZF_DIVIDER_SHOW -eq 1 ]] && header="${header}
${_clr[divider]}${FZF_DIVIDER_LINE}${_clr[rst]}"

      [[ -n "$header" ]] && fzf_opts="${fzf_opts} --header='${header}'"

      # optional functions: customize preview, prompt, options, header
      [[ "$(command -V _fzf-preview)" =~ "function" ]] && \
        fzf_opts="${fzf_opts} --preview='${SOURCE} --preview $mode {1}'"

      [[ "$(command -V _fzf-prompt)" =~ "function" ]] && \
        fzf_opts="${fzf_opts} --prompt='$(_fzf-prompt $mode)'"

      [[ "$(command -V _fzf-extra-opts)" =~ "function" ]] && \
        fzf_opts="${fzf_opts} $(_fzf-extra-opts $mode)"

      fzf_opts="${fzf_opts} --ansi --print-query"
      fzf_opts="${fzf_opts} --preview-window='right:50%:wrap'"
      fzf_opts="${fzf_opts} --tiebreak=index --no-hscroll --query='${query}'"

      # keys that can exit
      # expected_keys="enter,esc,ctrl-r,ctrl-^,alt-9,alt-0,ctrl-space"
      expected_keys="enter,${_fzf_keys[exit]},${_fzf_keys[reload]},${_fzf_keys[toggle_popout]}"
      expected_keys="${expected_keys},${_fzf_keys[mode_prev]},${_fzf_keys[mode_next]}"
      expected_keys="${expected_keys},${_fzf_keys[actions_menu]}"

      # TODO: only for count of fzf_modes
      [[ -n "$FZF_MODES" ]] && expected_keys="${expected_keys},f1,f2,f3,f4,f5"
      fzf_opts="${fzf_opts} --expect='$expected_keys'"

      if [ $FZF_CLEAR -eq 1 ]; then
        fzf_opts="${fzf_opts} --clear"
      else
        fzf_opts="${fzf_opts} --no-clear"
      fi

      FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

      # only output the text without piping to fzf
      if [[ $FZF_RAW_OUT -eq 1 ]]; then
        IFS=$'\n' result=($(_fzf-source $mode))
        printf "%s\n" "${result[@]}" | column -t
        exitkey=""
        exit 0
      fi

      # actually perform fzf command here
      IFS=$'\n' result=($(_fzf-source $mode | $fzf_cmd $fzf_cmd_args | sed 's/^ *//' ))

      # determine if query was submitted by identifying line exit key is on
      if [[ ${#result[@]} -gt 2 && $expected_keys == *${result[2]}* ]]; then
        query="$(echo ${result[1]} | xargs)"
        exitkey="$(echo ${result[2]})" # xargs on exitkey removes "ctrl-\"
        selected=(${result[@]:2})
      else
        query=""
        exitkey="$(echo ${result[1]})"
        selected=(${result[@]:1})
      fi

      _fzf-log "main results: \n${result[@]}\n"
      # TODO: find a way around buffering
      local lines=$(_fzf-source $mode | head -n 5)
      local log_lines=()
      [[ -n "$query" ]] && log_lines+=("query:\t${query}")
      [[ -n "$exitkey" ]] && log_lines+=("exit-key:\t${exitkey}")
      [[ -n "$selected[@]" ]] && log_lines+=("selected:\t${#selected[@]} items")
      for item in "${selected[@]}"; do log_lines+=("  ${item}") done

      # log_lines+=("\noptions: $fzf_opts")
      _fzf-log "main menu top 5: $has_query\n${lines[@]}\n--\n${log_lines[@]}"

      if [[ "$exitkey" == "enter" ]]; then
        _fzf-handle-result "echo" "$selected"
      fi

      if [[ "$exitkey" == "${_fzf_keys[actions_menu]}" ]]; then
        action_menu=("${selected[@]}")
      else
        action_menu=()
      fi
    fi
  done
}

_fzf-unset() {
  unset -f _fzf-result _fzf-source _fzf-preview _fzf-header _fzf-prompt
  unset -f _fzf-display _fzf-assign-default-vars _fzf-verify _fzf-log _fzf-main
  unset $FZF_LOGFILE $FZF_MODES $FZF_TRIGGERS $FZF_DEFAULT_MODE
  unset _clr cwd SOURCE lib _fzf_log_first
}

# main arguments handler to parse argument settings and invoke different outputs
_fzf-main() {

  # ensure correct functions are declared depending on options and assignments
  _fzf-verify

  # assign default keys and colors with optional override
  _fzf-assign-default-vars
  [[ "$(command -V _fzf-assign-vars)" =~ "function" ]] && \
    _fzf-assign-vars

  # flag to pipe output (list or preview) to stdout instead of fzf
  [[ "$1" == "--raw" ]] && \
    shift && FZF_RAW_OUT=1

  # generate preview content
  if [[ "$1" == "--preview" ]]; then
    shift && [[ "$(command -V _fzf-preview)" =~ "function" ]] \
      && eval "_fzf-preview $*"
  # output dynamic menu description
  elif [[ $1 == "--description" ]]; then
    shift && [[ "$(command -V _fzf-menu-description)" =~ "function" ]] && \
			eval "_fzf-menu-description $*"
  # show usage information on the command line
  elif [[ $1 == "--help" || $1 == "-h" ]]; then
    shift && echo "HELP"
  # launch main fzf display loop, remaining arguments should be lookup query
  else
    # clear && echo -e "\nLoading $SOURCE..."
    _fzf-display $@
  fi

}

_fzf-main $@
