#!/bin/zsh

# TODO:
#   - sorting modes (pid, cpu, mem, ellapsed time)
#   - ctrace live summary

sudo "" 2>/dev/null

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

RELOAD_ON_CHANGE=0
# FZF_DEFAULT_ACTION="${FZF_DEFAULT_ACTION:-ctrace}"
FZF_ACTIONS=("kill" "kill:9" "ctrace" "ctrace:verbose" "ltrace" "iotrace" "lsof" )
FZF_ACTION_DESCRIPTIONS=(
  "kill process (SIGTERM)"
  "kill process -9 (SIGKILL)"
  "ctrace process (only errors)"
  "ctrace process (all calls)"
  "ltrace process"
  "iotrace process"
  "list all files used by process(es)"
)

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"

  if [[ -n "$TMUX" ]]; then
    tmux_width=$(tmux display-message -p "#{window_width}")
    tmux_padding="-p60%"
    [[ $tmux_width -lt 400 ]] && tmux_padding="-p75%"
    [[ $tmux_width -lt 200 ]] && tmux_padding="-p90%"
    export FZF_TMUX_OPTS="${FZF_TMUX_OPTS:-${tmux_padding}}"
  fi
}

_fzf-command() {
  # nlwp: thread count, comm: shor t command name
  local fields="pid,ppid,user,%cpu,%mem,rss,etime,stat,tty,args"
  local sort="%cpu"
  local cmd="ps axf --sort ${sort} -o ${fields} \
    | sed \"s,$HOME,~,g\" \
    | grcat conf.ps"

  echo "${cmd}"
}

_fzf-extra-opts() {
  opts="--query=\"!fzf $*\""
  opts="${opts} --tac"
  opts="${opts} --header-lines=1"
  echo "$opts"
}

_fzf-result() {
  action="$1" && shift
  items=($@)
  _fzf-log "top.zsh result $action (${#items[@]}): \n${items[@]}"

  for item in "$items[@]"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    item_user=$(echo "$item" | sed -E 's/\S+\s+\S+\s+//' | cut -d' ' -f1)
    is_root=$([[ "$item_user" == "root" ]] && echo 1 || echo 0)

    case "$action" in
      'kill')
        echo "kill - id:$item_id, root:$is_root"
        sudo -E env PATH="$PATH" kill $item_id
        ;;
      'kill:9')
        echo "kill:9 - id:$item_id, root:$is_root"
        sudo -E env PATH="$PATH" kill -9 $item_id
        ;;
      'ctrace')
        echo "ctrace - id:$item_id, root:$is_root"
        sudo -E env PATH="$PATH" ctrace -p $item_id  \
        # ctrace -f "lstat,open"
        ;;
      'ctrace:verbose')
        echo "ctrace:verbose - id:$item_id, root:$is_root"
        sudo -E env PATH="$PATH" ctrace -v -p $item_id  \
        ;;
      'ltrace')
        # cat ~/wiki/_/cli/hyperfine.md | nvimpager -c -- -c "set term=ansi" -c "set ft=markdown" -c "syntax on" 
        # -n, --indent=NR     indent output by NR spaces for each call level nesting.
        # -a, --align=COLUMN  align return values in a secific column.
        # -b, --no-signals    don't print signals.
        # -c                  count time and calls, and report a summary on exit.
        # -f                  trace children (fork() and clone()).
        # -r                  print relative timestamps.
        # -s STRSIZE          specify the maximum string size to print.
        # -S                  trace system calls as well as library calls.
        # -t, -tt, -ttt       print absolute timestamps.
        # -T                  show the time spent inside each call.
        # tail -f < <(strace -p 1103935) |  bat --paging=never --color=always -lstrace
        # tail -n 500 /tmp/tmp.strace | nvimpager -c -- -c "set ft=strace"
        # nvimpager -c -- -c "set ft=strace" < <(strace -p 1103935)
        # ltrace -S -a 20 id -Z 
        # ltrace -c -p 71965 
        # ltrace -S neuron 2>&1 > /dev/null | vim -c ':set syntax=strace' 
        # ltrace -c "nvim" > tracing.log 
        echo "ltrace $item_id $is_root"
        [[ $is_root -eq 1 ]] \
          && sudo -E env PATH="$PATH" ltrace -p $item_id  \
          || ltrace -p $item_id
        ;;
      # 'ltrace:summary'|'ltrace:verbose')
      #   ;;
      # strace -C -S -p 1103935 -o /tmp/tmp.strace &  tail -f /tmp/tmp.strace |  bat --paging=never --color=always -lstrace
      # strace -S neuron 2>&1 > /dev/null | vim -c ':set syntax=strace' 
      # strace git 2>&1 > /dev/null | vim -c ':set syntax=strace' 
      'iotrace')
        echo "iotrace $item_id"
        [[ $is_root -eq 1 ]] \
          && sudo -E env PATH="$PATH" iotrace -p $item_id | bat -lstrace -p \
          || iotrace -p $item_id | bat -lstrace -p
        ;;
      # 'iotrace:forked')
      #   ;;

      'lsof')
        echo "lsof $item_id"
      ;;
    esac
  done
}

_fzf-prompt() {
  echo " ❯ "
}

_fzf-preview() {
  echo "These are my preview pids: $1"
}

source "${FZF_LIB}.zsh"
