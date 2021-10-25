#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib.zsh"

FZF_DIVIDER_SHOW=1
FZF_DIVIDER_LINE="―――――――――――――――――――――――――――――――――――――――――――――"

FZF_MODES=('available' 'installed' 'upgradeable')

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
    'installed')
      apt list --installed 2>/dev/null \
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
  selection="$(echo $* | cut -d' ' -f1)"

  # _fzf-log "result $mode: $selection"
  case "$mode" in
    'available')
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
  header=""
  mode="$1"
  mode_name="${FZF_MODES[$mode]}"
  case "$mode_name" in
    'available')
      header="${_clr[selected]}Available apt packages to install${_clr[rst]} - ^t: install"
      ;;
    'installed')
      header="${_clr[selected]}Installed apt packages${_clr[rst]} - ^t: remove"
      ;;
    'upgradeable')
      header="${_clr[selected]}Upgradeable apt packages${_clr[rst]} - ^t: upgrade"
      ;;
  esac
  hints=$(_fzf-mode-hints $mode)
  header="$header
$hints"
  echo "$header"
}

_fzf-preview() {
  mode="$1"
  shift
  selection="$*"
  case "$mode" in
    available|installed|upgradeable)
    yq eval '.Description-en' <(apt-cache show "$selection") 2>/dev/null \
      | bat --color always --plain
    apt-cache show $selection \
      | bat --language yaml --color always --plain
    ;;
  esac
}

_fzf-description() {
  id="$1"
  echo "fuck you $id"
  exit 0
}

source "$FZF_LIB"
