#!/bin/zsh

FZF_LOGFILE="/tmp/fzf.log"
setopt localoptions noglobsubst noposixbuiltins pipefail 2>> ${FZF_LOGFILE:-/dev/null}

FZF_DIVIDER_SHOW=${FZF_DIVIDER_SHOW:-0}
FZF_DIVIDER_LINE="${FZF_DIVIDER_LINE:-―――――――――――――――――――――――――――}"

declare -A _clr

if [[ ! -z ${FZF_LOGFILE} ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

_fzf_log_first=0
_fzf-log() {
  if [[ ! -z ${FZF_LOGFILE} ]]; then
    [[ _fzf_log_first -eq 0 ]] && printf "--------------------\n${SOURCE}\n" >> ${FZF_LOGFILE}
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
  _clr[divider]="${lc}${CLR_DIVIDER:-38;5;59}${rc}"
  _clr[rst]="${lc}0${rc}"
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

    # reset fzf log flag to output divider
    _fzf_log_first=0

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
    elif [[ "$exitkey" == "alt-9" ]]; then
      if [[ $mode -eq 1 ]]; then
        mode=$(($#FZF_MODES))
      else
        mode=$((($mode-1 % $#FZF_MODES)))
      fi
    elif [[ "$exitkey" == "alt-0" ]]; then
      mode=$((($mode % $#FZF_MODES) + 1))
    fi

    # optional functions: customize preview, prompt, options, header
    [[ "$(command -V _fzf-preview)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} --preview='${SOURCE} --preview ${FZF_MODES[mode]} {1}'"

    [[ "$(command -V _fzf-prompt)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} --prompt='$(_fzf-prompt ${FZF_MODES[mode]})'"

    [[ "$(command -V _fzf-extra-opts)" =~ "function" ]] && \
      fzf_opts="${fzf_opts} $(_fzf-extra-opts ${FZF_MODES[mode]})"

    # render header lines
    hints=$(_fzf-mode-hints "$mode")
    [[ -n "$hints" ]] && _fzf-log "hints:\t${hints}"
    header="${hints:-}"
    [[ "$(command -V _fzf-header)" =~ "function" ]] && header="$(_fzf-header $mode)"
    [[ $FZF_DIVIDER_SHOW -eq 1 ]] && header="${header}
${_clr[divider]}${FZF_DIVIDER_LINE}${_clr[rst]}"
    [[ -n "$header" ]] && fzf_opts="${fzf_opts} --header='${header}'"

    # keys that can exit
    expected_keys="enter,esc,ctrl-r,ctrl-^"
    [[ -n "$FZF_MODES" ]] && expected_keys="${expected_keys},f1,f2,f3,f4,f5,f6,f7,f8,f9,alt-9,alt-0"
    fzf_opts="${fzf_opts} --ansi --print-query"
    fzf_opts="${fzf_opts} --expect='$expected_keys'"
    fzf_opts="${fzf_opts} --clear --preview-window='right:50%:wrap'"
    fzf_opts="${fzf_opts} --tiebreak=index --no-hscroll --query='${query}'"

    FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

      # IFS=$'\n' result=($(printf "%s\n" ${lines[@]} | $fzf_cmd $fzf_cmd_args ) )
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
      if [[ -n "${FZF_MODES}" ]]; then
        _fzf-result ${FZF_MODES[mode]} ${result[@]}
      else
        _fzf-result ${result[@]}
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

  if [[ "$1" == "--preview" ]]; then
    shift
    # TODO: add error if not exist
    [[ "$(command -V _fzf-preview)" =~ "function" ]] && eval "_fzf-preview $*"
  elif [[ $1 == "--description" ]]; then
    shift
    # TODO: add error if not exist
    [[ "$(command -V _fzf-description)" =~ "function" ]] && eval "_fzf-description $*"
  elif [[ $1 == "--help" || $1 == "-h" ]]; then
    # TODO: make generic usage function that can be overridden
    echo "HELP"
  elif [[ $1 =~ "--mode" ]]; then
    # TODO: if modes defined, assign with --mode name or --mode=name
  else
    [[ "$(command -V _fzf-assign-vars)" =~ "function" ]] && _fzf-assign-vars
    # remaining arguments should be lookup query
    clear && echo -e "\nLoading $SOURCE..."
    _fzf-display $@

  fi

# TODO: unset variables
}

_fzf-main $@
