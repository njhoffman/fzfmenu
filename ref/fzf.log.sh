#!/bin/bash

FZF_LOGFILE=${FZF_LOGFILE:-"/tmp/fzf.log"}

if [[ -n ${FZF_LOGFILE} && ${FZF_LOGFILE} != 0 ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

# signal logger to output file header
_fzf_log_first=0
function debug {
  local clr_div='\033[1m'
  local clr_rst='\033[0m'

  local divider="${clr_div}"
  for _ in {1..40}; do divider="${divider}-"; done
  divider="\n${divider}${clr_rst}\n${SRC} - $$\n"

  if [[ -n ${FZF_LOGFILE} && ${FZF_LOGFILE} != 0 ]]; then
    [[ _fzf_log_first -eq 0 ]] \
      && printf "$divider" >>${FZF_LOGFILE}
    echo -en "\n$*" >>${FZF_LOGFILE}
    _fzf_log_first=1
  fi
}
