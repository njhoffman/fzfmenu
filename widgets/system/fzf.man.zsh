#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

FZF_DEFAULT_ACTION="view"

FZF_ACTIONS=(
  "view"
  "view:bat"
  "view:nvim"
  "view:popup"
)

FZF_ACTION_DESCRIPTIONS=(
  "view in manpager"
  "view in bat"
  "view in neovim"
  "view in popup window"
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
      'view')
          man $item_id
        ;;
      'view:bat')
        MANPAGER="sh -c 'col -bx | bat -l man -p --paging always'" \
          man $item_id
        ;;
      'view:nvim')
        nvim "+Tman visidata"
        echo "view:nvim $item_id"
        ;;
      'view:popup')
        tmux display-popup -b rounded -S 'fg=#00AA88'  \
           -h80% -w80% -E /bin/zsh \
          -c "man $item_id"
        echo "view:popup $item_id"
        ;;
    esac
  done
}

_fzf-prompt() {
  echo " man❯ "
}

_fzf-preview() {
  theme="Visual Studio Dark+"
  echo "$2" | tr -d '()' \
    | awk '{printf "%s ", $2} {print $1}' \
    | xargs -r man \
    | bat --theme "$theme" -l man -p --color always
  # echo "$2" | tr -d '()' \
  #   | awk '{printf "%s ", $2} {print $1}' \
  #   | xargs -r man \
  #   | col -bx \
  #   | bat --theme "$theme" -l man -p --color always
    # | tr -d '()'
    # | awk '{printf "%s ", $2} {print $1}'
}

_fzf-command() {

  # MANUAL SECTIONS
  # The standard sections of the manual include:

  # 1      User Commands
  # 2      System Calls
  # 3      C Library Functions
  # 4      Devices and Special Files
  # 5      File Formats and Conventions
  # 6      Games et. al.
  # 7      Miscellanea
  # 8      System Administration tools and Daemons
# search only names
# man -ka --names-only --regex 'foo'
  awk_recipe='
    BEGIN {FS="- ";OFS=" "}
    /\([1,3,4,8]\)/ {
      gsub(/\([0-9]\)/, "", $1)
      if (!seen[$0]++) { print color_id $1 reset "|" $2 }
    }
  '
  cmd="man -k . 2>/dev/null \
    | sort \
    | awk -v color_id='\033[1;34m' -v reset='\033[0m' '$awk_recipe' \
    | column -s'\|' -t"
  echo "${cmd}"
}

# _fzf-source
source "$FZF_LIB.zsh"
