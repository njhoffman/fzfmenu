#!/bin/zsh

SOURCE=${(%):-%x}
CWD="${0:A:h}"

FZF_LOGFILE="/tmp/fzf.log"
CACHE_FILE="$CWD/.menu.dat"
FZF_LIB="$CWD/fzf-lib.zsh"

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[desc]="${lc}${CLR_DESC:-38;5;59}${rc}"
  _clr[selected]="${lc}${CLR_MODE_SELECTED:-38;5;8;3}${rc}"
  _clr[rst]="${lc}0${rc}"
}

_fzf-menu-log() {
  if [[ ! -z ${FZF_LOGFILE} ]]; then
    printf "--------------------\n" >> ${FZF_LOGFILE}
    printf "  %s\n" $* >> ${FZF_LOGFILE}
  fi
}

_fzf-menu-parse-env() {
  while read env_item; do
    env_export="export \"${env_item/: /=}\""
    _fzf-log "setting for $1: \n $env_export"
    eval "$env_export"
  done< <(yq eval '.envs.[]' "$1")
}

_fzf-menu-build-cache() {
  fd_menu="fd --hidden -L -c never --no-ignore --type f \".menu.yml\" $CWD"
  menu_lines=""
  while read menu_file; do
    menu_len=$(yq eval '.actions | length' "$menu_file")
    echo -e "Processing $menu_len items from $menu_file"
    for ((i=0; i<=$menu_len - 1; i++)); do
      id=$(yq eval ".actions.[$i].id" "$menu_file")
      desc=$(yq eval ".actions.[$i].desc" "$menu_file")
      cmd=$(yq eval ".actions.[$i].cmd" "$menu_file")
      cmd_file="$(echo "$cmd" | cut -d' ' -f1)"
      cmd_dir=$(dirname "$menu_file")
      menu_lines="$menu_lines\n|$id|$desc|${cmd_dir}/${cmd_file}"
    done
  done < <(eval "$fd_menu")
  echo -e "$menu_lines" > "$CACHE_FILE"
  echo -e "Wrote $(cat ${CACHE_FILE} | wc -l) items to $CACHE_FILE"
}

_fzf-result() {
  mode="$1" && shift
  selection="$(echo $* | xargs | cut -d' ' -f1)"
  _fzf-log "fzf menu: $selection"
}

_fzf-extra-opts() {
  echo "--with-nth=..-2"
}

_fzf-source() {
  lines=()
  while read -r line; do
    id="$(echo "$line" | awk -F'|' '{print $2}')"
    desc="$(echo "$line" | awk -F'|' '{print $3}')"
    cmd="$(echo "$line" | awk -F'|' '{print $4}')"

    if [[ "$(echo $desc | xargs)" == "***" ]]; then
      desc="$(eval $(echo $cmd | xargs) --description $(echo $id | xargs))"
    fi

    lineout="${_clr[rst]}${_clr[id]}${id} ${_clr[desc]}${desc} ${cmd}${_clr[rst]}"

    lines+=( "$lineout" )
  done < <(cat ${CACHE_FILE} | sort | column -s '|' -o '|' -t)

  printf '%s\n' "${lines[@]}"
}

if [[ $1 == "--cache" ]]; then
  _fzf-menu-build-cache
else
  source "$FZF_LIB"
fi
