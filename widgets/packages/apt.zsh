#!/bin/zsh

SOURCE="${(%):-%N}"
cwd="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
fzf_lib="$cwd/../fzf-lib.zsh"

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[name]="${lc}${CLR_ID:-38;5;30}${rc}"
  # _clr[desc]="${lc}${CLR_DESC:-38;5;59}${rc}"
  _clr[desc]="${lc}${CLR_DESC:-0}${rc}"
  _clr[selected]="${lc}${CLR_MODE_SELECTED:-38;5;8;3}${rc}"

}

_fzf-source() {
  # TODO: apt list --verbose
  # zlib1g/groovy,now 1:1.2.11.dfsg-2ubuntu4 amd64 [installed,automatic]
  #   compression library - runtime
  mode="$1" && shift
  selection="$*"
  case "$mode" in
    'remove')
      apt list --installed \
        | sort  \
        | sed -u -r "s/^([^ ]+)(.*)/${_clr[name]}\1${_clr[desc]}\2${_clr[rst]}/"
      ;;
    *)
      apt-cache search '.*' \
        | sort  \
        | sed -u -r "s/^([^ ]+)(.*)/${_clr[name]}\1${_clr[desc]}\2${_clr[rst]}/"
      ;;
  esac
}

_fzf-result() {
  mode="$1" && shift
  selection="echo $* | cut -d' ' -f1"

  _fzf-log "result $mode: $selection"
  case "$mode" in
    'install')
      sudo apt-get install "$selection"
      ;;
    *)
    echo "result $mode: $selection"
      ;;
  esac
}

_fzf-prompt() {
  echo "apt❯ "
}

_fzf-header() {
  mode="$1"
  case "$mode" in
    'id')
      echo "${_clr[selected]}Echo package id${_clr[rst]}"
      ;;
    'install')
      echo "${_clr[selected]}Install package with apt${_clr[rst]}"
      ;;
    'upgrade')
      echo "${_clr[selected]}Upgrade available apt packages${_clr[rst]}"
      ;;
    'remove')
      echo "${_clr[selected]}Remove installed apt package${_clr[rst]}"
      ;;
    'info')
      echo "${_clr[selected]}Echo package id${_clr[rst]}"
      ;;

  esac
}

_fzf-preview() {
  mode="$1"
  shift
  selection="$*"
  case "$mode" in
    info|install|upgrade|remove)
    yq eval '.Description-en' <(apt-cache show "$selection") 2>/dev/null \
      | bat --color always --plain
    apt-cache show $selection \
      | bat --language yaml --color always --plain
    ;;
  esac
}

FZF_MODES=('info' 'install' 'upgrade' 'remove')

source "$fzf_lib"
