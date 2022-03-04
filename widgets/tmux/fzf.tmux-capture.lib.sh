#!/bin/bash

ROOTDIR="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd -P)"

CAPTURE_ALL_PANES=1
CAPTURE_ONLY_VISIBLE=0

function capture_active_pane() {
  # Calculating the scroll positions to capture only the visible contents in the panes.
  pane_vals=$(tmux display-message -p -t $1 '#{scroll_region_lower}-#{scroll_position}')
  scroll_height=$(echo $pane_vals | cut -f1 -d-)
  scroll_pos=$(echo $pane_vals | cut -f2 -d-)
}

function capture_pane() {
  # tmux capture-pane -p -J -t $1
  tmux capture-pane -S -E -pS -9999999 -t $1
}

function capture_pane_visible() {
  # Calculating the scroll positions to capture only the visible contents in the panes.
  pane_vals=$(tmux display-message -p -t $1 '#{scroll_region_lower}-#{scroll_position}')
  scroll_height=$(echo $pane_vals | cut -f1 -d-)
  scroll_pos=$(echo $pane_vals | cut -f2 -d-)
  tmuxcmd="tmux capture-pane -p -J -t $1 "
  # scoll_pos implies pane in copy mode
  if [[ -n $scroll_pos ]]; then
    bottom=$((scroll_height - scroll_pos))
    copyargs="-S -$scroll_pos  -E $bottom"
    tmuxcmd="$tmuxcmd $copyargs"
  fi
  exec "$tmuxcmd"
}

  # http://www.microsoft.com
function match_window {
  cur_window=$(tmux display-message -p '#I')
  IFS=$'\n' pane_list=($(tmux list-panes -F \
    '#{pane_active} #{pane_index} ' -t $cur_window \
    | sort -r \
    | cut -f2 -d' '))

  active_pane=$(tmux list-panes -F '#{pane_index} #{pane_active}' \
    | grep '1$' \
    | cut -f1 -d' ' \
    | sed 's/%//')

  for pane in "${pane_list[@]}"; do
    active_i=0
    [[ "$pane" == "$active_pane" ]] && active_i=1
    # http://www.doyouseeme.com
    _fzf-log "capturing pane $pane, win:$cur_window"
    tmpfile=$(mktemp --tmpdir="/tmp" "butlerXXXXXX.tmp")
    capture_pane "$cur_window.$pane" > $tmpfile
    outfile=$(tokenize_content "$tmpfile")

    prefix="${active_i}:${cur_window}.${pane}"

    # Sort and uniq the output
    cat $outfile \
      | egrep -o ".{$minchars,}" \
      | tac \
      | awk -v "prefix=$prefix" '{print prefix ":" $0}' \
      >> "$all_out"
    rm -f "$outfile"
  done
  _fzf-log "total matches: $(cat $all_out | wc -l)"
}

DATEREGEX='([12]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))'
URLREGEX='https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
GITURLREGEX='(git@|https:\/\/)([\w\.@]+)(\/|:)([\w,\-,\_]+)\/([\w,\-,\_]+)(.git){0,1}((\/){0,1})'
IPV4REGEX='[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
IPV6REGEX='[a-fA-F0-9]+:[a-fA-F0-9:]{2,}'
PATHREGEX='\\\\?([^\\/]*[\\/])*)([^\\/]+'
HASHREGEX='(([a-f0-9]*[a-f][a-f0-9]*)|([A-F0-9]*[A-F][A-F0-9]*))\b'
EMAILREGEX='^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
# hashes: docker - c3d808a58827, git - a7681d8, 6a4ea16d1d32e766763a123848b4616eb98bf343

function tokenize_content() {
  declare -A regexlist
  regexlist[url]="$URLREGEX"
  # regexlist[hash]="$HASHREGEX"
  regexlist[ip]="$IPV4REGEX"
  minchars=4
  FILTERLIST=()

  inpfile="$1"
  if [[ ! -f "$inpfile" ]]; then
    echo "Error: first argument needs to be a file - $1"
  fi
  outfile="$inpfile.out"

  cleanup() {
    rm -f $inpfile
  }
  [[ -z $BUTLERDEBUG ]] && trap 'cleanup' EXIT

  touch $outfile
  # cat > $inpfile
  pane_lines=$(cat $tmpfile | wc -l)
  _fzf-log "input: $tmpfile - $pane_lines lines"

  # TODO: change to sh syntax when possible
  for reg_name in "${(@k)regexlist[@]}"; do
    reg="${regexlist[$reg_name]}"
    cat $inpfile \
      | egrep -on $reg \
      | sed "s/$/:${pane_lines}:${reg_name}/g" \
      >> $outfile
  done

  lines=$(cat $outfile | wc -l)
  # http://www.googleyou.com
  _fzf-log "matches: $outfile $lines/$pane_lines lines"
  echo $outfile

  # for tkner in "${FILTERLIST[@]}"; do
  #   cat $inpfile | $tkner >> $tmpfile
  # done

}
