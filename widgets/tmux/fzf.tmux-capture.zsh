#!/bin/zsh

CWD="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd -P)"
FZF_LIB="$CWD/../../fzf-lib"

FZF_MODES=('pane' 'window' 'global')
FZF_DEFAULT_MODE=2
FZF_TOGGLES=('url' 'ip' 'path' 'hash')
FZF_MODES_HIDE_KEYS=1
FZF_TOGGLES_HIDE_KEYS=1
FZF_TOGGLES_DEFAULT=(1 1 0 0)

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[pane_id]="${lc}${CLR_PANE_ID:-38;5;30}${rc}"
  _clr[icon_active]="${lc}${CLR_ICON_ACTIVE:-38;5;30}${rc}"
  _clr[icon_type]="${lc}${CLR_ICON_TYPE:-38;5;30}${rc}"
  _clr[match_url]="${lc}${CLR_MATCH_URL:-38;5;30}${rc}"
  _clr[lines_before]="${lc}${CLR_LINES_BEFORE:-38;5;30}${rc}"
  if [[ -n "$TMUX" ]]; then
    pwidth=60
    winwidth=$(tmux display-message -p "#{client_width}")
    xpos=$(( ($winwidth / 2 ) - ($pwidth / 2 ) ))
    export FZF_TMUX_OPTS="-w $pwidth -h 15 -y 0 -x $xpos"
    _fzf-log "TMUX OPTS 3: $FZF_TMUX_OPTS"

    # export FZF_TMUX_OPTS="-w 80 -h 15 -x $xpos -y 0" # -y 0 -x $xpos -y 0"
  fi

}

_fzf-extra-opts() {
  opts="--header-first --no-preview --delimiter=' ' --with-nth=2.. --nth=4.. "
  # opts="${opts} --header-lines=1"
  echo "$opts"
}

_fzf-result() {
  action="$1" && shift
  items=($@)
  _fzf-log "${CWD} result $action (${#items[@]}): \n${items[@]}"

  for item in "$items[@]"; do
    # echo "butler $item"
  done
}

_fzf-preview() {
  echo "These are my preview pids: $1"
}

contains_element() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

_fzf-source() {
  all_out=$(mktemp --tmpdir="/tmp" "butlerXXXXXX.out")
  cleanup() {
    rm -f $all_out
  }
  [[ -z $BUTLERDEBUG ]] && trap 'cleanup' EXIT

  match_window

  output=()
  items=()
  cat "$all_out" | while read -r line; do
    is_active=$(echo "$line" | cut -f1 -d':')
    line=$(echo "$line"  | cut -f2- -d':')
    capture_pane=$(echo "$line" | cut -f1 -d':')
    line=$(echo "$line"  | cut -f2- -d':')
    capture_lines=$(echo "$line" | cut -f1 -d':')
    line=$(echo "$line"  | cut -f2- -d':')
    suffix_fields=$(echo "$line" | grep -o ':[^:]*:[^:]*$')
    regex_match=$(printf '%s\n' "${line//${suffix_fields}/}")
    pane_lines=$(echo "$suffix_fields" | cut -f2 -d':')
    regex_name=$(echo "$suffix_fields"  | cut -f3- -d':')

    contains_element "$regex_match" "${items[@]}"
    if [[ $? -eq 1 ]]; then
      icon=""
      [[ "$regex_name" == "url" ]] && icon="  "
      [[ "$regex_name" == "hash" ]] && icon="  "
      [[ "$regex_name" == "ip" ]] && icon="  "
      [[ "$regex_name" == "path" ]] && icon="  "
      [[ "$is_active" == "1" ]] && capture_pane="  "
      lines_before="-$(( $pane_lines - $capture_lines ))"
      # delimiter=0x2007
      output_line="$(\
        printf '%s %4s %6sL %s %s' \
        $regex_match $capture_pane $lines_before $icon $regex_match \
      )"
      output+=("$output_line")
      items+=("$regex_match")
    fi
  done

  printf "%s\n" "${output[@]}"
}

#             i      

source "$CWD/fzf.tmux-capture.lib.sh"

source "${FZF_LIB}.zsh"

# _fzf-source
