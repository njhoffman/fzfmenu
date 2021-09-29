#!/bin/zsh

FZF_LOGFILE="fzf.log"
setopt localoptions noglobsubst noposixbuiltins pipefail 2>> ${FZF_LOGFILE:-/dev/null}

declare -A __clr
__clr[mode_active]="${lc}${CLR_MODE_ACTIVE:-38;5;117}${rc}"
__clr[mode_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;68}${rc}"
__clr[rst]="${lc}0${rc}"

if [[ ! -z ${FZF_LOGFILE} ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

_fzf-log() {
  if [[ ! -z ${FZF_LOGFILE} ]]; then
    echo -e "\n$*" >> ${FZF_LOGFILE}
  fi
}

_fzf-verify() {
  # ensure functions exist: _fzf-source, _fzf-result
}

_fzf-display() {
  local selected num mode exitkey typ cmd_opts fzf_cmd_args

  _fzf-verify

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

    if [[ $exitkey = "ctrl-^" ]]; then
      if [[ $fzf_cmd == "fzf-tmux" ]]; then
        fzf_cmd="fzf"
        fzf_cmd_args=""
      else
        fzf_cmd="fzf-tmux"
        fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
      fi
    fi

    if [[ $exitkey =~ "f." ]]; then
      mode=${exitkey[$(($MBEGIN+1)),$MEND]}
    else
      mode=$((($mode % $#modes) + 1))
    fi

    for ((i=1; i<=${#modes}; i++)); do
      if [[ "${modes[i]}" == "${modes[mode]}" ]]; then
        hints="${hints}${__clr[mode_active]}F${i}: ${modes[i]}  ${__clr[rst]}"
      else
        hints="${hints}${__clr[mode_inactive]}F${i}: ${modes[i]}  ${__clr[rst]}"
      fi
    done

    [[ "$(command -V _fzf-preview)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} --preview='${SOURCE} --preview ${modes[mode]} {1}'"

    [[ "$(command -V _fzf-prompt)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} --prompt='$(_fzf-prompt ${modes[mode]})'"

    [[ "$(command -V _fzf-extra-opts)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} $(_fzf-extra-opts ${modes[mode]})"

    [[ "$(command -V _fzf-header)" =~ "function" ]] && \
      sel="$(_fzf-header ${modes[mode]})"

    _fzf-log "${fzf_preview} -- ${sel}"

    fzf_opts="${fzf_opts} --header='$sel
$hints'"
    fzf_opts="${fzf_opts} --ansi --print-query"
    fzf_opts="${fzf_opts} --expect='enter,esc,ctrl-r,f1,f2,f3,f4,f5,f6,f7,f8,f9,ctrl-],ctrl-^'"
    fzf_opts="${fzf_opts} --no-clear --preview-window='right:50%:wrap'"
    fzf_opts="${fzf_opts} --tiebreak=index --no-hscroll --query='${query}'"

    _fzf-log "hints: ${hints}\nmode: $mode\nfzf options: $fzf_opts"

    FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

    IFS=$'\n' result=($(_fzf-source ${modes[mode]} | $fzf_cmd $fzf_cmd_args ) )

    exitkey="${result[1]}"
    selected="${result[2]}"
    if [[ ${#result[@]} -gt 2 ]]; then
      query="${result[1]}"
      exitkey="${result[2]}"
      selected="${result[3]}"
    fi

    _fzf-log "QUERY: $query\nEXIT: $exitkey\nSELECTED: $selected\n"

    if [[ "$exitkey" == "enter" ]]; then
      _fzf-result ${modes[mode]} ${result[@]}
    fi
  done
}
