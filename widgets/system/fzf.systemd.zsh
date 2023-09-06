#!/bin/zsh

# TODO: toggle: system, user, static
# TODO: sort: status, name

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

FZF_TOGGLES=('system' 'user' 'inactive')
FZF_TOGGLES_HIDE_KEYS=1
FZF_TOGGLES_DEFAULT=(1 1 0)

FZF_SORT=('status' 'name' 'type')
FZF_SORT_HIDE_KEYS=1

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
FZF_DEFAULT_ACTION="follow"

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"

  if [[ -n "$TMUX" ]]; then
    tmux_width=$(tmux display-message -p "#{window_width}")
    tmux_padding="-p60%"
    [[ $tmux_width -lt 400 ]] && tmux_padding="-p70%"
    [[ $tmux_width -lt 200 ]] && tmux_padding="-p80%"
    export FZF_TMUX_OPTS="$tmux_padding"

    width=$(tput cols)
    if [[ $width -gt 100 || -n $FZF_TMUX  ]]; then
      opts="--preview-window :right,70%,nohidden"
    else
      opts="--preview-window :nowrap,hidden"
    fi

    # _fzf-log "\n\nOPTS $opts"
    # export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} $opts"
  fi
}

_fzf-extra-opts() {
  opts="\
    --delimiter=' '
    --with-nth=2..
    --nth=2.."

  echo "$opts"
}

_fzf-result() {
  action="$1" && shift
  items=($@)
  _fzf-log "${CMD} result $action (${#items[@]}): \n${items[@]}"

  for item in "$items[@]"; do
    item_id=$(echo "$item" | cut -d' ' -f3)
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
  echo " ❯ "
}

_fzf-preview() {
  unit="$2"
  manager="$3"
  env SYSTEMD_COLORS=1 \
    systemctl --$manager status --no-pager -- "$unit"
}

_fzf-awk() {
  autoload -U colors && colors
  local lc=$'\e[' rc=m prefix=""
  clr_green1="${lc}${CLR_ID:-38;5;30}${rc}"
  awk \
    -v green=${fg[green]} \
    -v manager=${MANAGER} \
    -v red=${fg[red]} \
    -v reset=$reset_color '
        $1 !~ /@\.(service|socket|target)$/ && !($1 in units) {
        unitname = $1
        otherarg = $2
        status = $3
        status_detail = $4
        description = $NF
        units[unitname] = 1
        if (unitname != "" && status != "") {
          if (status == "active" ) {
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
        print unitname " " manager " " indicator " " "["manager"]" " " unitname
      }
    }'
}

_fzf-source() {
  MANAGERS=(user system)
  for MANAGER in "${MANAGERS[@]}"; do
    local systemctl_options=(--full --no-legend --no-pager --plain)
    systemctl_options+=("--$MANAGER")
    cat < \
      <({
       systemctl list-units ${(Q)${(Z+n+)systemctl_options}} "$prefix*"
        systemctl list-unit-files ${(Q)${(Z+n+)systemctl_options}} "$prefix*"
      } | LC_ALL=C sort -b -f -k 1,1 -k 3,3r \
        | _fzf-awk)
  done
}


# _fzf-source
source "$FZF_LIB.zsh"
