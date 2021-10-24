#!/bin/zsh

FZF_LOGFILE="/tmp/fzf.log"
setopt localoptions noglobsubst noposixbuiltins pipefail 2>> ${FZF_LOGFILE:-/dev/null}

declare -A _clr

if [[ ! -z ${FZF_LOGFILE} ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

_fzf_log_first=0
_fzf-log() {
  if [[ ! -z ${FZF_LOGFILE} ]]; then
    [[ _fzf_log_first -eq 0 ]] && printf "--------------------\n" >> ${FZF_LOGFILE}
    echo -e "\n$*" >> ${FZF_LOGFILE}
    _fzf_log_first=1
  fi
}

_fzf-verify() {
  # ensure functions exist: _fzf-source, _fzf-result
}

_fzf-assign-default-vars() {
  local lc=$'\e[' rc=m
  _clr[mode_active]="${lc}${CLR_MODE_ACTIVE:-38;5;117}${rc}"
  _clr[mode_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;68}${rc}"
  _clr[rst]="${lc}0${rc}"
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
    fzf_opts="" hints="" query="" sel=""

    # reset fzf log flag to output divider
    _fzf_log_first=0

    # TODO: distinguish between ctrl-], ctrl-[

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

    # if key pressed was a function key
    if [[ $exitkey =~ "f." ]]; then
      mode=${exitkey[$(($MBEGIN+1)),$MEND]}
    else
      mode=$((($mode % $#FZF_MODES) + 1))
    fi

    # calculate what the selected mode is
    for ((i=1; i<=${#FZF_MODES}; i++)); do
      if [[ "${FZF_MODES[i]}" == "${FZF_MODES[mode]}" ]]; then
        hints="${hints}${_clr[mode_active]}F${i}: ${FZF_MODES[i]}  ${_clr[rst]}"
      else
        hints="${hints}${_clr[mode_inactive]}F${i}: ${FZF_MODES[i]}  ${_clr[rst]}"
      fi
    done

    # optional functions: customize preview, prompt, options, header
    [[ "$(command -V _fzf-preview)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} --preview='${SOURCE} --preview ${FZF_MODES[mode]} {1}'"

    [[ "$(command -V _fzf-prompt)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} --prompt='$(_fzf-prompt ${FZF_MODES[mode]})'"

    [[ "$(command -V _fzf-extra-opts)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} $(_fzf-extra-opts ${FZF_MODES[mode]})"

    [[ "$(command -V _fzf-header)" =~ "function" ]] && \
      sel="$(_fzf-header ${FZF_MODES[mode]})"

    _fzf-log "${fzf_preview} -- ${sel}"

    fzf_opts="${fzf_opts} --header='$sel
$hints'"
    fzf_opts="${fzf_opts} --ansi --print-query"
    fzf_opts="${fzf_opts} --expect='enter,esc,ctrl-r,f1,f2,f3,f4,f5,f6,f7,f8,f9,ctrl-],ctrl-^'"
    fzf_opts="${fzf_opts} --no-clear --preview-window='right:50%:wrap'"
    fzf_opts="${fzf_opts} --tiebreak=index --no-hscroll --query='${query}'"

    _fzf-log "hints: ${hints}\nmode: $mode\nfzf options: $fzf_opts"

    FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

    IFS=$'\n' result=($(_fzf-source ${FZF_MODES[mode]} | $fzf_cmd $fzf_cmd_args ) )

    exitkey="${result[1]}"
    selected="${result[2]}"
    if [[ ${#result[@]} -gt 2 ]]; then
      query="${result[1]}"
      exitkey="${result[2]}"
      selected="${result[3]}"
    fi

    _fzf-log "QUERY: $query\nEXIT: $exitkey\nSELECTED: $selected\n"

    if [[ "$exitkey" == "enter" ]]; then
      _fzf-result ${FZF_MODES[mode]} ${result[@]}
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

  if [[ "$1" == "--preview" ]]; then
    shift
    [[ "$(command -V _fzf-preview)" =~ "function" ]] && eval "_fzf-preview $*"
  elif [[ $1 == "--help" || $1 == "-h" ]]; then
    # TODO: make generic usage function that can be overridden
    echo "HELP"
  elif [[ $1 =~ "--mode" ]]; then
    # TODO: if modes defined, assign with --mode name or --mode=name
  else
    [[ "$(command -V _fzf-assign-vars)" =~ "function" ]] && _fzf-assign-vars
    # remaining arguments should be lookup query
    _fzf-display $@
  fi

# TODO: unset variables
}

_fzf-main $@
