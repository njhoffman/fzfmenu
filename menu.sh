#!/bin/bash

SOURCE=$(readlink "${BASH_SOURCE[0]}")
cwd="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
cache_file="$cwd/.menu.dat"

declare -A _clr

FZF_MENU_LOGFILE="fzf-menu.log"

if [[ ! -z ${FZF_MENU_LOGFILE} ]]; then
  [[ ! -f ${FZF_MENU_LOGFILE} ]] && touch ${FZF_MENU_LOGFILE}
fi

_fzf-menu-log() {
if [[ ! -z ${FZF_MENU_LOGFILE} ]]; then
  printf "\n--------------------\n\n" >> ${FZF_MENU_LOGFILE}
  printf "  %s\n" $* >> ${FZF_MENU_LOGFILE}
fi
}

_fzf-menu-msg () {
if [[ ! -z ${FZF_MENU_LOGFILE} ]]; then
  echo -e "\n$*" >> ${FZF_MENU_LOGFILE}
fi
}

_fzf-menu-parse-env() {
while read env_item; do
  env_export="export \"${env_item/: /=}\""
  _fzf-menu-msg "setting for $1: \n $env_export"
  eval "$env_export"
done< <(yq eval '.envs.[]' "$1")
}

_fzf-menu-build-cache() {
fd_menu="fd --hidden -L -c never --no-ignore --type f \".menu.yml\" $cwd"
menu_lines=""
while read menu_file; do
  menu_len=$(yq eval '.actions | length' "$menu_file")
  echo -e "Processing $menu_len items from $menu_file"
  for ((i=0; i<=$menu_len - 1; i++)); do
    id=$(yq eval ".actions.[$i].id" "$menu_file")
    desc=$(yq eval ".actions.[$i].desc" "$menu_file")
    menu_lines="$menu_lines\n| $id | $desc"
  done
done < <(eval "$fd_menu")
echo -e "$menu_lines" > "$cache_file"
echo -e "Wrote $(cat ${cache_file} | wc -l) items to $cache_file"
}

_fzf-menu-handler() {
echo -e "fzf menu handler! \n $*"
}

_fzf-menu-assign-vars() {
local lc=$'\e[' rc=m
_clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
_clr[desc]="${lc}${CLR_DESC:-38;5;59}${rc}"
_clr[mode_active]="${lc}${CLR_MODE_ACTIVE:-38;5;117}${rc}"
_clr[mode_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;68}${rc}"
_clr[selected]="${lc}${CLR_MODE_SELECTED:-38;5;8;3}${rc}"
_clr[rst]="${lc}0${rc}"
}

_fzf-menu-display() {
local selected num mode exitkey typ cmd_opts fzf_cmd_args
ORIG_FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS
query="$*"

_fzf-menu-assign-vars

fzf_cmd="fzf"
# if [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ] }; then
if [ -n "$TMUX_PANE" ] && ( [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ] ); then
  fzf_cmd="fzf-tmux"
  fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
fi

lines=()

while read -r line; do
  lineout=$(echo "$line" | awk -F'|'  \
    '{print "'${_clr[rst]}'"$1"'${_clr[id]}'"$2"'${_clr[desc]}'"$3 "'${_clr[rst]}'"}')
      lines+=( "$lineout" )
    done < <(cat $cache_file \
      | sort \
      | column -s '|' -o '|' -t)

    modes=('session' 'loc' 'global')

    if [[ -n ${FZF_MENU_DEFAULT_MODE} ]]; then
      mode=${FZF_MENU_DEFAULT_MODE}
    else
      mode=2
    fi

    exitkey='ctrl-r'
    while [[ "$exitkey" != "" && "$exitkey" != "esc" ]]; do
      fzf_opts=""

      if [[ $exitkey = "ctrl-^" ]]; then
        if [[ $fzf_cmd == "fzf-tmux" ]]; then
          fzf_cmd="fzf"
          fzf_cmd_args=""
        else
          fzf_cmd="fzf-tmux"
          fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
        fi
      fi
      if [[ $exitkey =~ "f." ]]; then
        mode=${exitkey[$(($MBEGIN+1)),$MEND]}
      fi
      case "$modes[$mode]" in
        'session')
          cmd_opts="-s"
          sel="${_clr[selected]}Session${_clr[rst]}"
          hints="${_clr[mode_active]}F1: session${_clr[rst]}"
          hints="${hints} ${_clr[mode_inactive]}F2: directory${_clr[rst]}"
          hints="${hints} ${_clr[mode_inactive]}F3: global${_clr[rst]}"
          ;;
        'loc')
          cmd_opts="-d"
          sel="${_clr[selected]}Directory local history $(pwd)${_clr[rst]}"
          hints="${_clr[mode_inactive]}F1: session${_clr[rst]}"
          hints="${hints} ${_clr[mode_active]}F2: directory${_clr[rst]}"
          hints="${hints} ${_clr[mode_inactive]}F3: global${_clr[rst]}"
          ;;
        'global')
          cmd_opts=""
          sel="${_clr[selected]}global history${_clr[rst]}"
          hints="${_clr[mode_inactive]}F1: session${_clr[rst]}"
          hints="${hints} ${_clr[mode_inactive]}F2: directory${_clr[rst]}"
          hints="${hints} ${_clr[mode_active]}F3: global${_clr[rst]}"
          ;;
      esac

      mode=$((($mode % ${#modes[@]}) + 1))

      fzf_opts="${fzf_opts} --with-nth=2.. -n1.. --ansi "
      fzf_opts="${fzf_opts} --expect='esc,ctrl-r,f1,f2,f3,ctrl-],ctrl-^' --print-query"
      fzf_opts="${fzf_opts} --header='$sel
      $hints'"
      fzf_opts="${fzf_opts} --no-clear --preview-window='right:50%:wrap'"
      fzf_opts="${fzf_opts} --preview='echo {1}' --tiebreak=index --no-hscroll --query='${query}'"
      fzf_preview="echo 'whatsup bitches'; echo {1}"
      # fzf_preview="source ${FZF_HISTDB_FILE}; histdb-detail ${HISTDB_FILE} {1}"

      _fzf-menu-log "${lines[@]}"
      _fzf-menu-msg "hints: ${hints}"
      _fzf-menu-msg "mode: $mode\nfzf options: $fzf_opts"
      FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"
      # IFS=$'\n' result=($(printf '%s\n' "${lines[@]}" | $fzf_cmd $fzf_cmd_args ))
      IFS=$'\n' result=($(printf '%s\n' "${lines[@]}" | $fzf_cmd $fzf_cmd_args ))
      # _fzf-menu-msg "${result}\n${exitkey}"
      query=""
      exitkey="${result[1]}"
      selected="${result[2]}"
      if [[ ${#result[@]} -gt 2 ]]; then
        query="${result[1]}"
        exitkey="${result[2]}"
        selected="${result[3]}"
      fi
      # selected="${(j: :)${(@z)result[3]}[@]:2}"
      _fzf-menu-msg "QUERY: $query\nEXIT: $exitkey\nSELECTED: $selected\n"
    done
  }

_fzf-menu-build-cache
_fzf-menu-display $@

SOURCE=$(readlink "${BASH_SOURCE[0]}")
cwd="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
cache_file="$cwd/.menu.dat"

declare -A _clr

FZF_MENU_LOGFILE="fzf-menu.log"

if [[ ! -z ${FZF_MENU_LOGFILE} ]]; then
  [[ ! -f ${FZF_MENU_LOGFILE} ]] && touch ${FZF_MENU_LOGFILE}
fi

_fzf-menu-log() {
  if [[ ! -z ${FZF_MENU_LOGFILE} ]]; then
    printf "--------------------\n" >> ${FZF_MENU_LOGFILE}
    printf "  %s\n" $* >> ${FZF_MENU_LOGFILE}
  fi
}

_fzf-menu-msg () {
  if [[ ! -z ${FZF_MENU_LOGFILE} ]]; then
    echo -e "\n$*" >> ${FZF_MENU_LOGFILE}
  fi
}

_fzf-menu-parse-env() {
  while read env_item; do
    env_export="export \"${env_item/: /=}\""
    _fzf-menu-msg "setting for $1: \n $env_export"
    eval "$env_export"
  done< <(yq eval '.envs.[]' "$1")
}

_fzf-menu-build-cache() {
  fd_menu="fd --hidden -L -c never --no-ignore --type f \".menu.yml\" $cwd"
  menu_lines=""
  while read menu_file; do
    menu_len=$(yq eval '.actions | length' "$menu_file")
    echo -e "Processing $menu_len items from $menu_file"
    for ((i=0; i<=$menu_len - 1; i++)); do
      id=$(yq eval ".actions.[$i].id" "$menu_file")
      desc=$(yq eval ".actions.[$i].desc" "$menu_file")
      menu_lines="$menu_lines\n| $id | $desc"
    done
  done < <(eval "$fd_menu")
  echo -e "$menu_lines" > "$cache_file"
  echo -e "Wrote $(cat ${cache_file} | wc -l) items to $cache_file"
}

_fzf-menu-handler() {
  echo -e "fzf menu handler! \n $*"
}

_fzf-menu-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[desc]="${lc}${CLR_DESC:-38;5;59}${rc}"
  _clr[mode_active]="${lc}${CLR_MODE_ACTIVE:-38;5;117}${rc}"
  _clr[mode_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;68}${rc}"
  _clr[selected]="${lc}${CLR_MODE_SELECTED:-38;5;8;3}${rc}"
  _clr[rst]="${lc}0${rc}"
}

_fzf-menu-display() {
  local selected num mode exitkey typ cmd_opts fzf_cmd_args
  ORIG_FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS
  query="$*"

  _fzf-menu-assign-vars

  fzf_cmd="fzf"
  if [ -n "$TMUX_PANE" ] && ( [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ] ); then
    fzf_cmd="fzf-tmux"
    fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
  fi

  lines=()

  while read -r line; do
    lineout=$(echo "$line" | awk -F'|'  \
      '{print "'${_clr[rst]}'"$1"'${_clr[id]}'"$2"'${_clr[desc]}'"$3 "'${_clr[rst]}'"}')
    lines+=( "$lineout" )
  done < <(cat $cache_file | sort | column -s '|' -o '|' -t)

  modes=('session' 'loc' 'global')

  if [[ -n ${FZF_MENU_DEFAULT_MODE} ]]; then
    mode=${FZF_MENU_DEFAULT_MODE}
  else
    mode=2
  fi

  exitkey='ctrl-r'
  while [[ "$exitkey" != "" && "$exitkey" != "esc" ]]; do
    fzf_opts=""

    if [[ $exitkey = "ctrl-^" ]]; then
      if [[ $fzf_cmd == "fzf-tmux" ]]; then
        fzf_cmd="fzf"
        fzf_cmd_args=""
      else
        fzf_cmd="fzf-tmux"
        fzf_cmd_args="${FZF_TMUX_OPTS:--p40%}"
      fi
    fi
    if [[ $exitkey =~ "f." ]]; then
      mode=${exitkey[$(($MBEGIN+1)),$MEND]}
    fi
    case "$modes[$mode]" in
      'session')
        cmd_opts="-s"
        sel="${_clr[selected]}Session${_clr[rst]}"
        hints="${_clr[mode_active]}F1: session${_clr[rst]}"
        hints="${hints} ${_clr[mode_inactive]}F2: directory${_clr[rst]}"
        hints="${hints} ${_clr[mode_inactive]}F3: global${_clr[rst]}"
        ;;
      'loc')
        cmd_opts="-d"
        sel="${_clr[selected]}Directory local history $(pwd)${_clr[rst]}"
        hints="${_clr[mode_inactive]}F1: session${_clr[rst]}"
        hints="${hints} ${_clr[mode_active]}F2: directory${_clr[rst]}"
        hints="${hints} ${_clr[mode_inactive]}F3: global${_clr[rst]}"
        ;;
      'global')
        cmd_opts=""
        sel="${_clr[selected]}global history${_clr[rst]}"
        hints="${_clr[mode_inactive]}F1: session${_clr[rst]}"
        hints="${hints} ${_clr[mode_inactive]}F2: directory${_clr[rst]}"
        hints="${hints} ${_clr[mode_active]}F3: global${_clr[rst]}"
        ;;
    esac

    mode=$((($mode % $#modes) + 1))

    fzf_opts="${fzf_opts} --with-nth=2.. -n1.. --ansi --expect='esc,ctrl-r,f1,f2,f3,ctrl-],ctrl-^' --print-query"
    fzf_opts="${fzf_opts} --header='$sel
$hints'"
    fzf_opts="${fzf_opts} --no-clear --preview-window='right:50%:wrap'"
    fzf_opts="${fzf_opts} --preview='echo {1}' --tiebreak=index --no-hscroll --query='${query}'"
    fzf_preview="echo 'whatsup bitches'; echo {1}"
    # fzf_preview="source ${FZF_HISTDB_FILE}; histdb-detail ${HISTDB_FILE} {1}"

    _fzf-menu-msg "${hints}"
    _fzf-menu-log "${lines[@]}"
    _fzf-menu-msg "mode: $mode\nfzf options: $fzf_opts"
    FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"
    IFS=$'\n' result=($(printf '%s\n' "${lines[@]}" | $fzf_cmd $fzf_cmd_args ))
    query=""
    exitkey="${result[1]}"
    selected="${result[2]}"
    if [[ ${#result[@]} -gt 2 ]]; then
      query="${result[1]}"
      exitkey="${result[2]}"
      selected="${result[3]}"
    fi
    # selected="${(j: :)${(@z)result[3]}[@]:2}"
    _fzf-menu-msg "QUERY: $query\nEXIT: $exitkey\nSELECTED: $selected\n"
  done
}

_fzf-menu-build-cache
_fzf-menu-display $@
