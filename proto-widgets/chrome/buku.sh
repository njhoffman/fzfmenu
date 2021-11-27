#!/usr/bin/env bash

select_tags() {
  buku --np -t|sed '$ d;s/^ *//;s/. /	/'|fzf --layout=reverse-list -m|grep -o -P '(?<=	).*(?= \()'
}

format_tag_list() {
  echo "${*}"|sed ':a;N;$!ba;s/\n/ + /g'
}


_video() {
  x-terminal-emulator -t mpv -e "mpv '$1'"
}
export -f _video

_open() {
  case $1 in
    *youtube.com*) _video "$1" ;;
    *youtu.be*) _video "$1" ;;
    *vimeo.com*) _video "$1" ;;
    *) x-www-browser "$1" ;;
  esac
}
export -f _open

printf -v jq '.[] | "\(.index) \(.uri) %s\(.tags)%s \(.title)"' "$(tput setaf 7)" "$(tput sgr0)"

main() {
  local choice=()
  mapfile -t choice < <(buku -p -j |
    jq -r "$jq" |
    SHELL=bash fzf \
    --ansi \
    --tac \
    --bind='enter:execute: _open {2}' \
    --expect='ctrl-d,ctrl-e' \
    --delimiter=' ' \
    --height=100% \
    --no-hscroll \
    --preview-window=down \
    --preview='buku -p {1}; w3m {2}' \
    --query="$*" \
    --with-nth=3..)

  selection=${choice[@]:1}

  case ${choice[0]} in
    ctrl-d)
      buku -d ${selection[0]%% *}
      main
      ;;
    ctrl-e)
      buku -w ${selection[0]%% *}
      main
      ;;
  esac
}

main "$*"


# while getopts 'th' opt; do
#   case "$opt" in
#     t)
#       SKIP_TAGS=false
#       ;;
#     h)
#       usage
#       exit
#       ;;
#     ?)
#       usage
#       exit 1
#       ;;
#   esac
# done
# shift $(( OPTIND - 1 ))

# tag_arg="-p"
# $SKIP_TAGS || {
#   tags=$(select_tags)

# [ -n "${tags}" ] && {
#   tag_list=$(format_tag_list "${tags}")
#   tag_arg="-t ${tag_list}"
# }
# }

# ids=$(buku --np "${tag_arg}" -f 3|tac|fzf --layout=reverse-list -m|cut -d '	' -f 1|tr '\n' ' ')

# [ -z "${ids}" ] && exit 1

# # shellcheck disable=SC2086
# buku -o ${ids}
