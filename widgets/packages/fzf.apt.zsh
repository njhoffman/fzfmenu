#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib.zsh"

FZF_DIVIDER_SHOW=1
FZF_DIVIDER_LINE="―――――――――――――――――――――――――――――――――――――――――――――"
FZF_MODES=('available' 'installed' 'upgradeable')


_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[menu_id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[menu_desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
  _clr[header]="${lc}${CLR_HEADER:-38;5;8;3}${rc}"
  _clr[key_name]="${lc}${CLR_HEADER_KEY:-38;5;252;1}${rc}"
  _clr[key_desc]="${lc}${CLR_HEADER_KEY_DESC:-38;5;8;1}${rc}"
  _clr[number]="${lc}${CLR_DESC_NUMBER:-38;5;81}${rc}"
}

_fzf-assign-mode() {
  mode="$1" && shift
  mode_name="${FZF_MODES[$mode]}"
  case "$mode_name" in
    'available')
      FZF_ACTIONS=("install" "${FZF_DEFAULT_ACTIONS[@]}")
      FZF_ACTION_DESCRIPTIONS=(
        "install package(s)"
        "${FZF_DEFAULT_ACTION_DESCRIPTIONS[@]}"
      )
      ;;
    'installed')
      FZF_ACTIONS=("upgrade" "${FZF_DEFAULT_ACTIONS[@]}")
      FZF_ACTION_DESCRIPTIONS=(
        "upgrade package(s)"
        "${FZF_DEFAULT_ACTION_DESCRIPTIONS[@]}"
      )
      ;;
    'upgradeable')
      FZF_ACTIONS=("remove" "${FZF_DEFAULT_ACTIONS[@]}")
      FZF_ACTION_DESCRIPTIONS=(
        "remove package(s)"
        "${FZF_DEFAULT_ACTION_DESCRIPTIONS[@]}"
      )
      ;;
  esac
}

_fzf-source() {
  # TODO: apt list --verbose
  mode="$1" && shift
  mode_name="${FZF_MODES[$mode]}"
  case "$mode_name" in
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
  header="${_clr[header]}"
  case "$mode_name" in
    'available')
      header="${header}Available apt packages to install ("
      header="${header}${_clr[key_name]}enter: ${_clr[key_desc]}install"
      header="${header})"
      ;;
    'installed')
      header="${header}Installed apt packages ("
      header="${header}${_clr[key_name]}enter: ${_clr[key_desc]}echo_name"
      header="${header}, ${_clr[key_name]}ctrl-d: ${_clr[key_desc]}delete"
      header="${header})"
      ;;
    'upgradeable'|*)
      header="${header}Upgradeable apt packages ("
      header="${header}${_clr[key_name]}enter: ${_clr[key_desc]}echo_name"
      header="${header})"
      ;;
  esac
  header="${header}${_clr[rst]}"
  hints=$(_fzf-mode-hints $mode)
  header="$header
$hints"
  echo "$header"
}

_fzf-preview() {
  mode="$1" && shift
  mode_name="${FZF_MODES[$mode]}"
  selection="$*"
  case "$mode_name" in
    available|installed|upgradeable)
    yq eval '.Description-en' <(apt-cache show "$selection") 2>/dev/null \
      | bat --color always --plain
    apt-cache show $selection \
      | bat --language yaml --color always --plain
    ;;
  esac
}

# remove warning message so it doesn't interfere with count
_apt-count() {
  # warn_msg="WARNING: apt does not have a stable CLI interface. Use with caution in scripts."
  warn_msg="apt does not have a stable CLI interface"
  sed "/${warn_msg}/id" | sed "/^Listing...$/d" | sed "/^$/d" | tee -a $FZF_LOGFILE | wc -l
}

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

_fzf-extra-opts() {
  opts=""
  opts="${opts} --header-first"
  echo "$opts"
}

_fzf-menu-description() {
  id="$1"
  mode="${FZF_DEFAULT_MODE:-}"
  [[ $id =~ install$ ]] && mode="available"
  [[ $id =~ remove$ ]] && mode="installed"
  [[ $id =~ upgrade$ ]] && mode="upgradeable"

  msg="${_clr[rst]}${_clr[number]}"
	case "$mode" in
		"installed")
			count=$(apt list --installed 2>/dev/null | _apt-count)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} installed packages to remove${_clr[rst]}"
			;;
		"available")
      count=$(apt-cache search '.*' 2>/dev/null | _apt-count)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} available packages to install${_clr[rst]}"
			;;
    "upgradeable")
			count=$(apt list --upgradable 2>/dev/null | _apt-count)
      msg="${msg}$(printf "%'d" $count)${_clr[menu_desc]} available packages to upgrade${_clr[rst]}"
			;;
	esac
  # return count, if 0 then non-zero exit to skip item
  [ $count -ne 0 ] && echo -e "$msg" && exit 0
  _fzf-log "skipping: $id - $count" && exit 1
}

_fzf-result() {
  action="$1" && shift
  selection="$(echo $* | cut -d' ' -f1)"
  _fzf-log "${SOURCE} result $action: $selection"
  case "$action" in
    'install')
      sudo apt-get install "$selection"
      ;;
    # 'upgrade'|'remove')
    #   ;;
    *)
      echo "result $mode: $selection"
      ;;
  esac
}

source "$FZF_LIB"