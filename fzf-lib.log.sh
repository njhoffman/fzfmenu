#!/bin/bash

if [[ -n ${FZF_LOGFILE} && ${FZF_LOGFILE} != 0 ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

# signal logger to output file header
_fzf_log_first=0
_fzf-log() {
  if [[ -n ${FZF_LOGFILE} && ${FZF_LOGFILE} != 0 ]]; then
    [[ _fzf_log_first -eq 0 ]] \
      && printf "--------------------\n${SOURCE}\n" >> ${FZF_LOGFILE}
    echo -e "\n$*" >> ${FZF_LOGFILE} && _fzf_log_first=1
  fi
}
