#!/bin/zsh

RELOAD_ON_CHANGE=0
SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib.zsh"
FZF_ACTIONS=("kill" "kill_9" "ctrace" "ltrace" "iotrace")
FZF_ACTION_DESCRIPTIONS=(
  "kill process"
  "kill process -9"
  "ctrace process"
  "ltrace process"
  "iotrace process"
)

# while :; do
#   case "$1" in
#     -h|--help)
#       LESS=-FEXR less <<HELP
# fztop SEARCH

# USAGE:
#   at runtime a the following keybinds are available:

#   ctrl-x
#     will send SIGTERM to the selected process
#   F9
#     will send SIGKILL to the selected process
# HELP
#       exit ;;
#     *) break
#   esac
# done
# answer=$(( ($numerator + ($denominator - 1) / $denomonator))

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
}

_fzf-source() {
  grc --colour=on -es -c conf.ps \
    \ps axf -o pid,ppid,user,%cpu,%mem,rss,time,stat,tty,args \
    | sed "s,$HOME,~,g"
    # grc --colour=on -es -c conf.ps \
    #   | ps af -o pid,ppid,user,%cpu,%mem,rss,time,tty,args \
    #   | sed 's|/home/nicholas|~|g' \
    #   | fzf --ansi --header-lines=1 --preview='S_COLORS=always pidstat -du --human -p {1}' \
    #   | sed 's/^ *//' | cut -f1 -d' '
}

_fzf-extra-opts() {
  source_command="grc --colour=on -es -c conf.ps \
    \ps axf -o pid,ppid,user,%cpu,%mem,rss,time,stat,tty,args \
    | sed 's,/home/nicholas,~,g'"

  # opts="--query="!fzf $*" \
  opts="--nth=1,2,3,9,10"
  opts="${opts} --header-lines=1"
  # opts="${opts} --bind-keys=ctrl-r:reload:'$source_command'"
  # opts="${opts},ctrl-x:execute(kill {2})+reload('$source_command')"
  # [ $RELOAD_ON_CHANGE -eq 1 ] && \
  #   opts="${opts},change:reload:'$source_command'"
  echo "$opts"
}

_fzf-result() {
  echo -e "my resljts.. $*"
}

_fzf-prompt() {
  echo "ps❯ "
}

_fzf-preview() {
  echo "These are my preview pids: $1"
}


# _fzf-source
source "$FZF_LIB"
