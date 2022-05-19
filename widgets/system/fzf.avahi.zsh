#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

FZF_DEFAULT_ACTION="view"

FZF_ACTIONS=(
  "ssh"
)

FZF_ACTION_DESCRIPTIONS=(
  "SSH to target address"
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
      'ssh')
          echo "ssh" $item_id
        ;;
    esac
  done
}

_fzf-prompt() {
  echo " avahi❯ "
}

_fzf-preview() {
  # echo "$2" | tr -d '()' \
  #   | awk '{printf "%s ", $2} {print $1}' \
  #   | xargs -r man \
  #   | col -bx \
  #   | bat --theme "$theme" -l man -p --color always
    # | tr -d '()'
    # | awk '{printf "%s ", $2} {print $1}'
}

_fzf-source() {
# avahi-browse \
#   --all \
#   --parsable \
#   --terminate \
#   --resolve 2>/dev/null
#   headers="_;Interface;Protocol;Name;Type;Domain;Address;IP;Port;Attr"
#   fields="active iface prot name type domain host ip port attr"
#   while read -r line; do
#     IFS=';' read -r  active iface prot name net_type domain host ip attrs \
#       <<< $(echo $line | tr -cd '\11\12\15\40-\176')
#     printf "%s|%s|%s|%s|%s\n" $active $iface $net_type $name $ip
#   done <<< $(printf "%s\n" $headers && cat ./avahi.txt) \
#     | column -s'\|' -t
  # cmd="cat $(pwd)/avahi.txt | column -s';' -t"

  headers="_;Interface;Protocol;Name;Type;Domain;Address;IP;Port;Attr"
  fields="active iface prot name type domain host ip port attr"
  # (echo "$headers" && avahi-browse --all --parsable --resolve --terminate 2>/dev/null) \
  avahi-browse --all --parsable --resolve --terminate 2>/dev/null \
    | while read -r line; do
      # IFS=';' read -r active iface prot name net_type domain host ip attrs
        IFS=';' read -r active iface prot name net_type domain host ip
        <<< $(echo "$line" | tr -cd '\11\12\15\40-\176')
        printf "%s|%s|%s|%s|%s\n" $active $iface $net_type $name $ip
      done \
    | column -s'|' -t

      # printf "%-2s %-10s %-20s %-15s %s\n" $active $iface $net_type $name $ip
  # printf "%s\n" $cmd
}

# _fzf-command
source "${FZF_LIB}.zsh"
