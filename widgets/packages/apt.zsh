#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib.zsh"

FZF_DIVIDER_SHOW=1
FZF_DIVIDER_LINE="―――――――――――――――――――――――――――――――――――――――――――――"

FZF_MODES=('available' 'installed' 'upgradeable')
FZF_ACTIONS=("install" "upgrade" "remove")

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[menu_id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[menu_desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
  # _clr[desc]="${lc}${CLR_DESC:-1;3;30}${rc}"
  # _clr[desc]="${lc}${CLR_DESC:-0}${rc}"
  _clr[selected]="${lc}${CLR_MODE_SELECTED:-38;5;8;3}${rc}"
  # _clr[number]="${lc}${CLR_DESC_NUMBER:-1;34}${rc}"
  _clr[number]="${lc}${CLR_DESC_NUMBER:-38;5;81}${rc}"
}

_fzf-source() {
  # TODO: apt list --verbose
  mode="$1" && shift
  selection="$*"
  case "$mode" in
    'installed')
      apt list --installed 2>/dev/null \
        | sort  | sed -u -r \
          "s/^([^ ]+)(.*)/${_clr[menu_id]}\1${_clr[menu_desc]}\2${_clr[rst]}/"
      ;;
    *)
      apt-cache search '.*' \
        | sort  | sed -u -r \
          "s/^([^ ]+)(.*)/${_clr[menu_id]}\1${_clr[menu_desc]}\2${_clr[rst]}/"
      ;;
  esac
}

_fzf-prompt() {
  echo " apt❯ "
}

_fzf-header() {
  mode="$1" && shift
  mode_name="${FZF_MODES[$mode]}"
  header=""
  case "$mode_name" in
    'available')
      header="${_clr[selected]}Available apt packages to install${_clr[rst]} - enter: install"
      ;;
    'installed')
      header="${_clr[selected]}Installed apt packages${_clr[rst]} - enter: remove"
      ;;
    'upgradeable'|*)
			header="${_clr[selected]}Upgradeable apt packages${_clr[rst]} - enter: upgrade"
      ;;
  esac
  hints=$(_fzf-mode-hints $mode)
  header="$header
$hints"
  echo "$header"
}

_fzf-preview() {
  mode="$1" && shift
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

# remove so it doesn't interfere with count
# warn_msg="WARNING: apt does not have a stable CLI interface. Use with caution in scripts."
warn_msg="apt does not have a stable CLI interface"

_fzf-menu-visible() {
  command -v "apt"

  count=0
  # dont show if no menus to upgrade
	if [[ "$mode" == "upgradeable" ]]; then
    count=$(apt list --upgradable | _apt-count)
    echo $count
	fi
  echo 1
}

_apt-count() {
  sed "/${warn_msg}/id" | sed "/^Listing...$/d" | sed "/^$/d" | tee -a $FZF_LOGFILE | wc -l
}


_fzf-menu-description() {
  id="$1"
  mode="${FZF_DEFAULT_MODE:-}"
  [[ $id =~ install$ ]] && mode="available"
  [[ $id =~ remove$ ]] && mode="installed"
  [[ $id =~ upgrade$ ]] && mode="upgradeable"

  msg="${_clr[rst]}${_clr[number]}"
	case "$mode" in
		installed)
			count=$(apt list --installed 2>/dev/null | _apt-count)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} installed packages to remove${_clr[rst]}"
			;;
		available)
      count=$(apt-cache search '.*' 2>/dev/null | _apt-count)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} available packages to install${_clr[rst]}"
			;;
		upgradeable)
			count=$(apt list --upgradable 2>/dev/null | _apt-count)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} available packages to upgrade${_clr[rst]}"
			;;
	esac

  # return count, if 0 then non-zero exit to skip item
  [ $count -ne 0 ] && echo -e "$msg" && exit 0
  _fzf-log "skipping: $id - $count" && exit 1
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

source "$FZF_LIB"
