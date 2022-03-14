#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

FZF_LOGFILE=${FZF_LOGFILE:-"/tmp/fzf.log"}
# SRC="${SRC:-${BASH_SOURCE[0]}}"
FZF_VERBOSE=${FZF_VERBOSE:-0}
FZF_TMPDIR="${FZF_TMPDIR:-/tmp/fzf}"
FZF_TMUX=${FZF_TMUX:-0}
FZF_DEFAULT_COMMAND="${FZF_DEFAULT_COMMAND:-}"
FZF_TMUX_OPTS="${FZF_TMUX_OPTS:--p80%}"
FZF_RAW_OUT=${FZF_RAW_OUT:-0}
FZF_DELIMITER="${FZF_DELIMITER:- }"
FZF_PREVIEW_CMD="${FZF_PREVIEW_CMD:-}"
FZF_PREVIEW_NOWRAP=${FZF_PREVIEW_NOWRAP:-}

export FZF_PID=${FZF_PID:-$PPID}

if [[ -n ${FZF_LOGFILE} && ${FZF_LOGFILE} != 0 ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

log_colors=(
  '\033[38;5;30m'
  '\033[38;5;40m'
  '\033[38;5;50m'
  '\033[38;5;60m'
  '\033[38;5;70m'
  '\033[38;5;80m'
)
_log_idx=${_log_idx:-0}
_start_time=$(date "+%M%S%3N")

function log {
  local clr_div='\033[38;5;9m'
  local clr_rst='\033[0m'
  local clr_head='\033[1m'
  local clr_time='\033[38;5;38m'

  local div="${clr_div}"
  for _ in {1..50}; do div="${div}-"; done
  div="\n${div}${clr_rst}"
  div="${div}\n${clr_head}${SRC} $$ $PPID${clr_rst}\n"

  curr_time=$(date "+%M%S%3N") 2>/dev/null
  prefix=$((${curr_time#0} - ${_start_time#0})) 2>/dev/null
  prefix="${clr_time}${prefix}:${clr_rst} "

  if [[ -n ${FZF_LOGFILE} && ${FZF_LOGFILE} != 0 ]]; then
    [[ $_log_idx -eq 0 ]] \
      && printf "$div\n" >>${FZF_LOGFILE}
    echo -en "\n${prefix} $*" >>${FZF_LOGFILE}
    _log_idx=$((_log_idx + 1))
  fi
  _start_time=$(date "+%M%S%3N")
}

function log_args {
  ARGV=($@)
  for i in $(seq ${#ARGV[@]}); do
    j=$((i - 1))
    debug "arg${i}: ${ARGV[$j]}"
  done
}

function debug {
  [ -n "$FZF_VERBOSE" ] && log "${*}"
}

function tmpfile_read {
  pidfile="$FZF_TMPDIR/$FZF_PID.tmp"
  if [[ -f $pidfile ]]; then
    source "$pidfile"
  fi
}

function tmpfile_write {
  [[ ! -d $FZF_TMPDIR ]] && mkdir -p "$FZF_TMPDIR"
  pidfile="$FZF_TMPDIR/$FZF_PID.tmp"
  printf '#!/bin/bash\n' >"$pidfile"
  printf "FZF_MODE=$FZF_MODE \n" >>"$pidfile"
  printf "FZF_TMUX=$FZF_TMUX\n" >>"$pidfile"
}
