#!/bin/zsh

FZF_LOGFILE="/tmp/fzf.log"
setopt localoptions noglobsubst noposixbuiltins pipefail 2>> ${FZF_LOGFILE:-/dev/null}


# If fzf was started in full screen mode, it will not switch back to the original screen, so you'll have to manually run tput rmcup to return
# TODO: look into push to top instead of clear to preserve history
FZF_CLEAR=1
FZF_DIVIDER_SHOW=${FZF_DIVIDER_SHOW:-0}
FZF_DIVIDER_LINE="${FZF_DIVIDER_LINE:-―――――――――――――――――――――――――――}"
FZF_RAW_OUT=0

FZF_SUBMENU=""
FZF_ACTIONS=("${FZF_ACTIONS[@]}" "echo_name" "echo_preview" "yank_name" "yank_preview")
FZF_ACTION_DESCRIPTIONS=(
  "${FZF_ACTION_DESCRIPTIONS[@]}"
  "echo the first column",
  "echo what is displayed in preview pane",
  "yank the first column to clipboard",
  "yank the preview pane content to the clipboard"
)

declare -A _clr

if [[ ! -z ${FZF_LOGFILE} ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

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

_fzf-assign-default-vars() {
  local lc=$'\e[' rc=m
  _clr[mode_active]="${lc}${CLR_MODE_ACTIVE:-38;5;117}${rc}"
  _clr[mode_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;68}${rc}"
  _clr[divider]="${lc}${CLR_DIVIDER:-38;5;59}${rc}"
  _clr[action_id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[action_desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
  _clr[rst]="${lc}0${rc}"
}

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

_fzf-default-result() {
  mode="$1"
  action="$2"
  _fzf-log "line: $* \n--"
  if [[ "$action" == "echo_name" ]]; then
    "echo name"
  elif [[ "$action" == "echo_preview" ]]; then
    "echo preview"
  elif [[ "$action" == "yank_name" ]]; then
    "yank name"
  elif [[ "$action" == "yank_preview" ]]; then
    "yank preview"
  else
    if [[ -n "${FZF_MODES}" ]]; then
      _fzf-result $action ${FZF_MODES[mode]} ${result[@]}
    else
      _fzf-result $action ${result[@]}
    fi
  fi
}


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

_fzf-display() {
  local selected num mode exitkey typ cmd_opts fzf_cmd_args

  ORIG_FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS
  query="$*"

  fzf_cmd="fzf"
  if [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ] }; then
    fzf_cmd="fzf-tmux"
    fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
  fi

  if [[ -n ${FZF_DEFAULT_MODE} ]]; then
    mode=${FZF_DEFAULT_MODE}
  else
    mode=1
  fi

  exitkey='ctrl-r'

  while [[ "$exitkey" != "" && "$exitkey" != "esc" && "$exitkey" != "enter" ]]; do
    fzf_opts="" query="" header=""

    _fzf_log_first=0

    # if showing an actions submenu
    if [ -n "$FZF_SUBMENU" ]; then
      #   fzf_source_cmd="_fzf-default-actions-source"
      header="Action on id: $fzf_id"
      fzf_opts=""
      [[ -n "$header" ]] && fzf_opts="${fzf_opts} --header='${header}'"
      FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

      # only output the text without piping to fzf
      if [[ $FZF_RAW_OUT -eq 1 ]]; then
        IFS=$'\n' result=($(_fzf-default-actions-source ${FZF_MODES[mode]}))
        printf "%s\n" "${result[@]}" | column -t
        exitkey=""
        exit 0
      fi

      # actually perform fzf command here
      IFS=$'\n' result=($(_fzf-default-actions-source ${FZF_MODES[mode]} | $fzf_cmd $fzf_cmd_args ))

      exitkey="$(echo ${result[1]} | xargs)"
      selected="$(echo ${result[2]} | xargs)"
      if [[ ${#result[@]} -gt 2 ]]; then
        query="$(echo ${result[1]} | xargs)"
        exitkey="$(echo ${result[2]} | xargs)"
        selected="$(echo ${result[3]} | xargs)"
      fi

      _fzf-log "our results: ${#result[@]} \n${result[@]}"

      # TODO: find a way around buffering
      local lines=$(_fzf-default-actions-source ${FZF_MODES[mode]} | head -n 5)
      _fzf-log "${lines[@]}"
      local log_lines=()
      [[ -n "$query" ]] && log_lines+=("query:\t${query}")
      [[ -n "$exitkey" ]] && log_lines+=("exit:\t${exitkey}")
      [[ -n "$selected" ]] && log_lines+=("select:\t${selected}")
      # log_lines+=("\noptions: $fzf_opts")
      _fzf-log "submenu: \n${log_lines[@]}"

      if [[ "$exitkey" == "enter" ]]; then
        _fzf-default-result $mode ${selected}
        _fzf-log "$mode ${selected}"
      fi

      if [[ $exitkey != "ctrl-r" ]]; then
        FZF_SUBMENU=""
      fi

    else
      # TODO: make popout key customizeable, detect if available
      if [[ $exitkey = "ctrl-^" ]]; then
        if [[ $fzf_cmd == "fzf-tmux" ]]; then
          fzf_cmd="fzf"
          fzf_cmd_args=""
        else
          fzf_cmd="fzf-tmux"
          fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
        fi
      fi

      # if key pressed was a function key or a mode-left / mode-right key
      if [[ $exitkey =~ "f." ]]; then
        mode=${exitkey[$(($MBEGIN+1)),$MEND]}
      elif [[ "$exitkey" == "alt-9" ]]; then
        if [[ $mode -eq 1 ]]; then
          mode=$(($#FZF_MODES))
        else
          mode=$((($mode-1 % $#FZF_MODES)))
        fi
      elif [[ "$exitkey" == "alt-0" ]]; then
        mode=$((($mode % $#FZF_MODES) + 1))
      fi

      # render header lines
      hints=$(_fzf-mode-hints "$mode")
      [[ -n "$hints" ]] && _fzf-log "hints:\t${hints}"
      header="${hints:-}"
      [[ "$(command -V _fzf-header)" =~ "function" ]] && header="$(_fzf-header $mode)"

      [[ $FZF_DIVIDER_SHOW -eq 1 ]] && header="${header}
      ${_clr[divider]}${FZF_DIVIDER_LINE}${_clr[rst]}"

      [[ -n "$header" ]] && fzf_opts="${fzf_opts} --header='${header}'"

      # optional functions: customize preview, prompt, options, header
      [[ "$(command -V _fzf-preview)" =~ "function" ]] && \
        fzf_opts="${fzf_opts} --preview='${SOURCE} --preview ${FZF_MODES[mode]} {1}'"

      [[ "$(command -V _fzf-prompt)" =~ "function" ]] && \
        fzf_opts="${fzf_opts} --prompt='$(_fzf-prompt ${FZF_MODES[mode]})'"

      [[ "$(command -V _fzf-extra-opts)" =~ "function" ]] && \
        fzf_opts="${fzf_opts} $(_fzf-extra-opts ${FZF_MODES[mode]})"

      # keys that can exit
      expected_keys="enter,esc,ctrl-r,ctrl-^,alt-9,alt-0,ctrl-space"
      [[ -n "$FZF_MODES" ]] && expected_keys="${expected_keys},f1,f2,f3,f4,f5"

      fzf_opts="${fzf_opts} --ansi --print-query"
      fzf_opts="${fzf_opts} --expect='$expected_keys'"
      fzf_opts="${fzf_opts} --preview-window='right:50%:wrap'"
      fzf_opts="${fzf_opts} --tiebreak=index --no-hscroll --query='${query}'"

      if [ $FZF_CLEAR -eq 1 ]; then
        fzf_opts="${fzf_opts} --clear"
      else
        fzf_opts="${fzf_opts} --no-clear"
      fi

      FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

      # only output the text without piping to fzf
      if [[ $FZF_RAW_OUT -eq 1 ]]; then
        IFS=$'\n' result=($(_fzf-source ${FZF_MODES[mode]}))
        printf "%s\n" "${result[@]}" | column -t
        exitkey=""
        exit 0
      fi

      # actually perform fzf command here
      IFS=$'\n' result=($(_fzf-source ${FZF_MODES[mode]} | $fzf_cmd $fzf_cmd_args ))

      exitkey="$(echo ${result[1]} | xargs)"
      selected="$(echo ${result[2]} | xargs)"
      if [[ ${#result[@]} -gt 2 ]]; then
        query="$(echo ${result[1]} | xargs)"
        exitkey="$(echo ${result[2]} | xargs)"
        selected="$(echo ${result[3]} | xargs)"
      fi

      # TODO: find a way around buffering
      local lines=$(_fzf-source ${FZF_MODES[mode]} | head -n 5)
      _fzf-log "${lines[@]}"
      local log_lines=()
      [[ -n "$query" ]] && log_lines+=("query:\t${query}")
      [[ -n "$exitkey" ]] && log_lines+=("exit:\t${exitkey}")
      [[ -n "$selected" ]] && log_lines+=("select:\t${selected}")
      # log_lines+=("\noptions: $fzf_opts")
      _fzf-log "${log_lines[@]}"

      if [[ "$exitkey" == "enter" ]]; then
        _fzf-default-result $mode ${selected}

      fi

      if [[ $exitkey = "ctrl-space" ]]; then
        fzf_id="$(echo $selected | cut -d' ' -f1)"
        FZF_SUBMENU="$fzf_id"
        # exitkey="ctrl-r"
      else
        FZF_SUBMENU=""
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

_fzf-main() {
  _fzf-verify
  _fzf-assign-default-vars

  [[ "$(command -V _fzf-assign-vars)" =~ "function" ]] && \
    _fzf-assign-vars

  [[ "$1" == "--raw" ]] && \
    shift && FZF_RAW_OUT=1

  if [[ "$1" == "--preview" ]]; then
    # TODO: add error if not exist
    shift && [[ "$(command -V _fzf-preview)" =~ "function" ]] \
      && eval "_fzf-preview $*"
  elif [[ $1 == "--description" ]]; then
    shift && [[ "$(command -V _fzf-menu-description)" =~ "function" ]] && \
			eval "_fzf-menu-description $*"
  elif [[ $1 == "--help" || $1 == "-h" ]]; then
    # TODO: make generic usage function that can be overridden
    shift && echo "HELP"
  elif [[ $1 =~ "--mode" ]]; then
    # TODO: if modes defined, assign with --mode name or --mode=name
  else
    # transition screen in between fzf-menu switches
    # clear && echo -e "\nLoading $SOURCE..."
    # remaining arguments should be lookup query
    _fzf-display $@
    # clear && echo -e "\nLoading $SOURCE..."
  fi

# TODO: unset variables

}

_fzf-main $@
