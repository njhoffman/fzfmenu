#!/bin/bash

if [[ -n ${FZF_LOGFILE} && ${FZF_LOGFILE} != 0 ]]; then
  [[ ! -f ${FZF_LOGFILE} ]] && touch ${FZF_LOGFILE}
fi

# signal logger to output file header
_fzf_log_first=0
_fzf-log() {
  local clr_div="\\033[1m"
  local clr_rst="\\033[0m"
  local src="${SOURCE/$HOME/~}"

  local divider="${clr_div}"
  for _ in {1..40}; do divider="${divider}-"; done
  divider="\n${divider}${clr_rst}\n${src}\n"

  if [[ -n ${FZF_LOGFILE} && ${FZF_LOGFILE} != 0 ]]; then
    [[ _fzf_log_first -eq 0 ]] \
      && printf "$divider" >> ${FZF_LOGFILE}
    echo -e "\n$*" >> ${FZF_LOGFILE}
    _fzf_log_first=1
  fi
}
