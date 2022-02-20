#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

FZF_DEFAULT_ACTION="view"

FZF_ACTIONS=(
  "start"
  "stop"
  "restart"
  "enable"
  "enable:now"
  "disable"
  "edit"
  "journal"
  "follow"
)

FZF_ACTION_DESCRIPTIONS=(
  "start service"
  "stop service"
  "restart service"
  "enable service"
  "enable service now"
  "disable service"
  "edit service"
  "journal service"
  "follow service"
)

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
}

# _fzf-extra-opts() {
#   opts="${opts} --nth=1,2,3,-1"
#   echo "$opts"
# }


_fzf-result() {
  action="$1" && shift
  items=($@)
  _fzf-log "${CMD} result $action (${#items[@]}): \n${items[@]}"

  for item in "$items[@]"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    case "$action" in
      'start')
        echo "start $item_id"
        ;;
      'stop')
        echo "stop $item_id"
        ;;
      'restart')
        echo "restart $item_id"
        ;;
      'enable')
        echo "enable $item_id"
        ;;
      'disable')
        echo "disable $item_id"
        ;;
      'edit')
        echo "edit $item_id"
        ;;
    esac
  done
}

_fzf-prompt() {
  echo " systemd❯ "
}

_fzf-preview() {
  theme="Visual Studio Dark+"
  echo "$2" | tr -d '()' \
    | awk '{printf "%s ", $2} {print $1}' \
    | xargs -r man \
    | bat --theme "$theme" -l man -p --color always
  # echo "$2" | tr -d '()' \
  #   | awk '{printf "%s ", $2} {print $1}' \
  #   | xargs -r man \
  #   | col -bx \
  #   | bat --theme "$theme" -l man -p --color always
    # | tr -d '()'
    # | awk '{printf "%s ", $2} {print $1}'
}

_fzf-command() {
  local systemctl_options=(--full --no-legend --no-pager)
  systemctl_options+=($('--user --system' '')) || :
   # --ansi --tiebreak=index ${(Q)${(Z+n+)fzf_options}} ${(Q)${(Z+n+)${_fzf_complete_preview_systemctl_status/\$SYSTEMCTL_OPTIONS/$systemctl_options}}} ${(Q)${(Z+n+)FZF_DEFAULT_OPTS}} -- "$@" < \
   prefix=""
   # active (running) active(waiting) active(plugged) active(listening) active (exited)
   # inactive (dead)
   # service|socket|target|mount|device
   #          ⭘ ⏼  ○ ●
   local lc=$'\e[' rc=m
   clr_green1="${lc}${CLR_ID:-38;5;30}${rc}"

   cat
      <({
          systemctl list-units ${(Q)${(Z+n+)systemctl_options}} "$prefix*"
          systemctl list-unit-files ${(Q)${(Z+n+)systemctl_options}} "$prefix*"
      } |
          LC_ALL=C sort -b -f -k 1,1 -k 3,3r |
          awk \
              -v green=${fg[green]} \
              -v red=${fg[red]} \
              -v reset=$reset_color '
              $1 !~ /@\.(service|socket|target)$/ && !($1 in units) {
                  unitname = $1
                  otherarg = $2
                  status = $3
                  status_detail = $4
                  description = $NF
                  units[unitname] = 1

                  if (status == "active") {
                    if (status_detail == "running") {
                      indicator = green " " reset
                    } else if (status == "exited") {
                      indicator = green " " reset
                    } else {
                      indicator = green " " reset
                    }
                  } else if (status == "failed") {
                      indicator = red " " reset
                  } else {
                      indicator = " "
                  }

                  print indicator, unitname, $(NF-1)
              }')
  echo "${cmd}"
}

# _fzf-source
source "$FZF_LIB.zsh"
