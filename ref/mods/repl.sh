#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SRC="${BASH_SOURCE[0]}"

declare -A clr
lc=$'\e[' rc=m
clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
clr[desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
clr[rst]="${lc}0${rc}"

DATA_SRC="none"
# DATA_SRC="cat example.json"
# DATA_SRC="314K from Stdin"


FZF_MODES=('sh' 'grep' 'awk' 'jq' 'sed')
FZF_MODE="${FZF_DEFAULT_MODE:-1}"
# other modes: nodejs, python, go, xq, jq, xml
#   awk  sed grep -i -n  awk           

declare -A FZF_ACTIONS
FZF_ACTIONS[pipe:add]="add current pipe to flow"
FZF_ACTIONS[pipe:remove]="remove current pipe and edit previous"
FZF_ACTIONS[pipe:edit]="edit whole pipe flow command"
FZF_ACTIONS[stash]="add current eval line to list for later"
FZF_ACTIONS[stdout]="choose stdout destination"
FZF_ACTIONS[load:file]="choose a file for input"
FZF_ACTIONS[load:sample]="load sample data depending on tool"

FZF_ACTIONS_SORT=(
  "pipe:add" "pipe:remove" "pipe:edit" "stash"
  "stdout" "load:file""load:sample" "cat:id"
  "cat:preview" "yank:id" "yank:preview"
)

FZF_DEFAULT_ACTION="${FZF_DEFAULT_ACTION:-pipe:add}"
FZF_PREVIEW_NOWRAP=1
jq_logic1='[
path(..) |
  map(select(type=="string") // "[]") |
  join(".") | split(".[]") | join("[]")
  ] | map("." + .) | unique | .[]'

jq_logic2='
def path2text($value):
  def tos: if type == "number" then . else tojson end;
  reduce .[] as $segment ("";  .
    + ($segment
       | if type == "string" then "." + . else "[\(.)]" end))
  + " = \($value | tos)";

paths(scalars) as $p
  | getpath($p) as $v
  | $p | path2text($v)
'

jq_logic3='
[
  path(..)
  | map(
      if type == "number" then
          "[]"
      else
          tostring
      end
  )
  | join(".")
  | split(".[]")
  | join("[]")
]
| unique
| map("." + .)
| .[]'


function fzf_results {
  action="$1" && shift
  items=($@)
  case "$action" in
    'sh')
      echo "echo 'removing or upgrading ${items[*]}'"
      ;;
    *) fzf_result_default "$action" "${item}" ;;
  esac
  # done
}

function fzf_command_stash {
  # echo -e "stash one\nstash two\nstash three"
  echo ""
}

function fzf_command_examples {
  mode_name="${FZF_MODES[$(($FZF_MODE - 1))]}"
  case "$mode_name" in
    sh) cat "$HOME/git/fzfmenu/ref/mods/repl-data/sh.examples";;
    grep) cat "$HOME/git/fzfmenu/ref/mods/repl-data/grep.examples";;
    # jq) fzf_command_jq "$mode_name" ;;
    # sed) fzf_command_sed "$mode_name" ;;
    # awk) fzf_command_awk "$mode_name" ;;
    *) echo -e "example one\nexample two" ;;
  esac
}

function fzf_command {
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(fzf_options)"
  # mode-display-hints
  # fzf_command_stash
  fzf_command_examples
}

function fzf_jq_preview() {
  lc=$"\x1b" rc=m
  clr_gray="${lc}[0;30${rc}"
  clr_rst="${lc}[0${rc}"
  JQ_PREVIEW="jq -r --color-output $JQ_REPL_ARGS"
  <"$input" jq -r "$jq_logic3" | sort | uniq  | \
    sed 's/^ \+//g' | fzf \
    --preview "$JQ_PREVIEW {q} $input 2>/dev/null" \
    --delimiter=" " \
    --preview-window="down:80%:nohidden" \
    --height="95%" \
    --bind "tab:replace-query"
      # --bind "ctrl-n:down+replace-query"
}

input="$HOME/index.md"

function fzf_preview() {
  # mode="$1" && shift
  mode=${FZF_MODE:-$FZF_DEFAULT_MODE}
  mode_name="${FZF_MODES[$((mode - 1))]}"
  selection=("$2")
  query="$3"

  # debug "mode: $mode_name - query: $query - sel: ${selection[*]}"
  debug "query: $query -sel: ${selection[*]}"

  case "$mode_name" in
    # sh) FZF_PREVIEW_CMD="<$input bash -c {q}" ;;
    sh) /bin/bash -c "${query}" | grcat conf.docker-machinels;;
    grep)
      debug "query: $query"
      export GREP_COLORS="ms=01;32"
      eval "$HOME/bin/cgrep ${query} ${input}"
      # # grep) FZF_PREVIEW_CMD="<$input grep {q}" ;;
      # # export GREP_COLORS="ms=01;31:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36"

      ;;
    awk) FZF_PREVIEW_CMD="<$input awk {q}" ;;
    sed) FZF_PREVIEW_CMD="<$input sed {q}" ;;
    ruby) FZF_PREVIEW_CMD="ruby -e {q}";;
    python) FZF_PREVIEW_CMD="python -c {q}";;
    nodejs) FZF_PREVIEW_CMD="node {q}";;
    go) FZF_PREVIEW_CMD="go {q}";;
    jq) fzf_jq_preview ;;
  esac
}

function fzf_options {
  mode=${FZF_MODE:-$FZF_DEFAULT_MODE}
  mode_name="${FZF_MODES[$((mode - 1))]}"
  prompt="${mode_name:-   }"
  [[ -n  "$mode_name" ]] \
    && prompt=" ${prompt} "

  [[ "$mode_name" == "grep" ]] \
    && query='-E -i "\b\w{4}\b"'

  opts="\
    --query='${query:-}'
    --bind 'tab:replace-query'
    --prompt='$prompt'
    --preview-window='nowrap:down,80%'
    --header-lines=1"

  echo "${opts}"
}

# shellcheck source=SCRIPTDIR/fzf.sh
FZF_DEFAULT_COMMAND="$SRC --command"

source "../fzf.sh"

# input_arg="${1:-}"
# if [[ -z "$input_arg" || "$input_arg" == "-" ]]; then
#   input="$(mktemp)"
#   trap 'rm -f $input' EXIT
#   cat /dev/stdin > "$input"
# else
#   input="${input_arg}"
# fi
