#!/bin/zsh


SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib.zsh"

# TODO: ctrace:summary
# FZF_ACTIONS=("kill" "kill:9" "ctrace" "ctrace:verbose" "ltrace" "iotrace" "lsof" )
# FZF_ACTION_DESCRIPTIONS=(
#   "kill process (SIGTERM)"
#   "kill process -9 (SIGKILL)"
#   "ctrace process (only errors)"
#   "ctrace process (all calls)"
#   "ltrace process"
#   "iotrace process"
#   "list all files used by process(es)"
# )

TARGET_DIR="$HOME/git"
TMUXP_DIR="$HOME/.tmuxp"
RAW=0

CLR_RESET="\e[0m"
CLR_PROJECT="\e[0;37m" # white
CLR_TMUXP="\e[1;34m" # light blue
CLR_UPTIME="\e[1;35m"
CLR_DESCRIPTION="\e[1;3;30m" # gray
# CLR_SESSION_EXISTS="\033[1m" # bold white
CLR_SESSION_EXISTS="\e[38;5;81m" # bold white
# green:       '\033[38;2;0;180;70m',

#                             
#                       
ICON_DIR=" "
ICON_SESSION=" "
ICON_TMUXP=" "

function usage() {
  echo "Usage ..."
}

if [[ $# -gt 0 ]]; then
  if [[ ! -d "$1" ]]; then
    echo "Directory not found: $1 - using default $TARGET_DIR"
  else
    TARGET_DIR="$1"
  fi
fi

# output list of directory names with special handling
# for sessions existing or defined in TMUXP_DIR
function _fzf-source() {
  declare -A projects && declare -A tmuxps && declare -A sessions
  declare -a all_names && declare -a session_list

  # populate names from TARGET_DIR
  for dir in "$TARGET_DIR/"*/; do
    base_dir="$(basename $dir)"
    projects[$base_dir]="$dir"
    all_names+=("$base_dir")
  done

  # get defined tmuxp sessions in TMUX_DIR with TMUX_PREFIX if defined
  for tmuxp_file in "${TMUXP_DIR}/${TMUX_PREFIX}"*; do
    base_name=$(echo "$tmuxp_file" | sed "s/.yaml\|${TMUX_PREFIX}-//g" | xargs -I{} basename {})
    tmuxps[$base_name]="$tmuxp_file"
    all_names+=("$base_name")
  done

  # sessions currently running
  IFS=$'\n' session_list=($(tmux list-sessions -f "#{m:${TMUX_PREFIX}*,#{session_name}}"))
  for sess in "${session_list[@]}"; do
    base_name=$(echo "${sess%%:*}" | sed "s/${TMUX_PREFIX}-//g")
    sessions[$base_name]="$sess"
    all_names+=("$base_name")
  done

  all_names=($(printf "%s\n" "${all_names[@]}" | sort | uniq))
  output=""
  for name in "${all_names[@]}"; do
    session_name="$name"
    [[ -n "$TMUX_PREFIX" && "$TMUX_PREFIX" != "$name" ]] \
      && session_name="${TMUX_PREFIX}-${name}"

    title="$name" && description="" && id="" && icon=""
    if [[ -d "$TARGET_DIR/$name" ]]; then
      icon="${CLR_PROJECT}${ICON_DIR}${CLR_RST}"
      title="${CLR_PROJECT}${name}${CLR_RESET}"
      description="${TARGET_DIR//${HOME}/~}/${name}"
    fi

    if [[ ! -z "${tmuxps[$name]:-}" ]]; then
      icon="${CLR_TMUXP}${ICON_TMUXP}${CLR_RST}"
      title="${CLR_TMUXP}${name}${CLR_RESET}"
      filename="${tmuxps[$name]}"
      description=$(grep 'description:' "${filename}" \
        | cut -d ':' -f2- \
        | sed 's/"//g' \
        | sed 's/^[[:space:]]\+//g')
    fi

    if [[ ! -z "${sessions[$name]:-}" ]]; then
      icon="${CLR_SESSION_EXISTS}${ICON_SESSION}${CLR_RST}"
      title="${CLR_SESSION_EXISTS}${name}${CLR_RST}"
      session_create=$(tmux list-sessions -f "#{m:${session_name},#{session_name}}" -F "#{session_created}")
      uptime=$((($( date +%s) - $session_create) / 60))
      description="Session created${CLR_UPTIME} ${uptime} ${CLR_DESCRIPTION}minutes ago"
    fi

    output+="${icon}|${title}|${CLR_DESCRIPTION}${description}${CLR_RESET}\n"
  done
  echo -e "${output}" | column -t -s'|'
}


_fzf-extra-opts() {
  # opts="--query=\"!fzf $*\""
  # opts="${opts} --nth=1,2,3,-1"
  # opts="${opts} --tac"
  # opts="${opts} --header-lines=1"
  # [ $RELOAD_ON_CHANGE -eq 1 ] && \
  #   opts="${opts},change:reload:'$source_command'"
  echo "$opts"
}

_fzf-handle-result() {
  action="$1" && shift
  items=($@)
  item_ids=($(printf "%s\n" ${items[@]} | sed 's/ \+/\t/g' | cut -f2))

  if [[ "$action" == "echo" ]]; then
    printf "%s\n" ${item_ids[@]}
  elif [[ "$action" == "yank" ]]; then
    printf "%s\n" ${items_ids[@]} | xsel --clipboard
    echo "Copied ${#items[@]} item names to clipboard"
  fi
}

_fzf-prompt() {
  echo " sessions❯ "
}

_fzf-preview() {
  echo "These are my preview pids: $*"
}
# _fzf-source

# if [[ $RAW -eq 1 ]]; then
#   printf "$(_fzf-source)" | column -s'\|' -t
#   exit 0
# fi

# display_dir="${TARGET_DIR/$HOME/\~}"
# fzf_cmd="fzf"

# fzf_opts="${fzf_opts} --query='${query}'"

source "$FZF_LIB"
