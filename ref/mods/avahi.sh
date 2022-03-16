#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SRC="${BASH_SOURCE[0]}"

declare -A FZF_ACTIONS
FZF_ACTIONS[ssh]="ssh to target address"

FZF_ACTIONS_SORT=(
  "ssh"
  "cat:id"
  "cat:preview"
  "yank:id"
  "yank:preview"
)

FZF_TMUX_OPTS="-w100"

function fzf_results {
  action="$1" && shift
  items=($@)
  # echo "echo 'Performing $action on ${items[*]}'"
  for item in "${items[@]}"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    debug "$action: $item"
    case "$action" in
      'ssh') echo "ssh ${item}" ;;
      *) fzf_result_default "$action" "${item}" ;;
    esac
  done
}

function fzf_command {
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(fzf_options)"
  # headers="_|Interface|Protocol|Name|Type|Domain|Address|IP|Port|Attr"
  h=("Iface" "IP" "Port" " Host" "Name" " Type")
  printf "%8.8s %15.15s %5.5s %-20.20s %15.15s %-25.25s\n" \
    "${h[0]}" "${h[1]}" "${h[2]}" "${h[3]}" "${h[4]}" "${h[5]}"

  fields="resolved iface prot name type domain host ip port attr"
  avahi-browse \
    --terminate \
    --parsable \
    --all \
    --resolve 2>/dev/null \
    | grep --line-buffered -v 'IPv6' \
    | while read -r line; do
      IFS=';' read -r resolved iface prot name net_type domain host ip port attrs
      <<<$(echo $line | tr -cd '\11\12\15\40-\176')
      printf "%8.8s %15.15s %5.5s %-20.20s %15.15s %-25.25s\n" \
        "$iface" "$ip" "$port" "$host" "$name" "$net_type"
    done || true
}

function fzf_preview() {
  # mode="$1" && shift
  mode_name="${FZF_MODES[$((FZF_MODE - 1))]}"
  selection="$1"
  echo "selection:" "${selection[@]}"
}

function fzf_options {
  opts="\
  --tac
  --header-lines=1
  --delimiter=' '
  --with-nth=1..
  --preview-window='hidden:nowrap'"
  echo "${opts}"
}

FZF_DEFAULT_COMMAND="$SRC --command"
source "../fzf.sh"
