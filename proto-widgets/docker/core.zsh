#!/usr/bin/env zsh

autoload -U colors
colors

_fzf_feed_fifo() (
  command rm -f "$1"
  mkfifo "$1"
  cat <&0 > "$1" &
)

__fzf_comprun() {
  if [[ "$(type _fzf_comprun 2>&1)" =~ function ]]; then
    _fzf_comprun "$@"
  elif [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; }; then
    shift
    if [ -n "$FZF_TMUX_OPTS" ]; then
      fzf-tmux ${(Q)${(Z+n+)FZF_TMUX_OPTS}} -- "$@"
    else
      fzf-tmux -d ${FZF_TMUX_HEIGHT:-40%} -- "$@"
    fi
  else
    shift
    fzf "$@"
  fi
}

# Extract the name of the command. e.g. foo=1 bar baz**<tab>
__fzf_extract_command() {
  local token tokens
  tokens=(${(z)1})
  for token in $tokens; do
    token=${(Q)token}
    if [[ "$token" =~ [[:alnum:]] && ! "$token" =~ "=" ]]; then
      echo "$token"
      return
    fi
  done
  echo "${tokens[1]}"
}


_fzf_complete_tabularize() {
  if [[ $# = 0 ]]; then
    cat
    return
  fi

  awk \
    -v FS=${FS:- } \
    -v colors_args=${(pj: :)@} \
    -v reset=$reset_color '
      BEGIN {
      split(colors_args, colors, " ")
    }
  {
    str = $0
    for (i = 1; i <= length(colors); ++i) {
      field_max[i] = length($i) > field_max[i] ? length($i) : field_max[i]
      fields[NR, i] = $i
      pos = index(str, FS)
      str = substr(str, pos + 1)
    }
  if (pos != 0) {
    fields[NR, i] = str
  }
}
END {
  for (i = 1; i <= NR; ++i) {
    for (j = 1; j <= length(colors); ++j) {
      printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), colors[j], fields[i, j], reset
    }
  if ((i, j) in fields) {
    printf "  %s", fields[i, j]
  }
  printf "\n"
  }
}
'
}

_fzf_complete_colorize() {
  if [[ $# = 0 ]]; then
    cat
    return
  fi

  awk \
    -v colors_args=${(pj: :)@} \
    -v reset=$reset_color '
      BEGIN {
      split(colors_args, colors, " ")
      header = 1
    }
  header {
  delete fields
  fields[1] = 1
  header = 0

  for (i = 2; i <= length($0); ++i) {
    if (substr($0, i - 1, 1) == " " && substr($0, i, 1) != " ") {
      fields[length(fields) + 1] = i
    }
}
}
{
  total = 0
  for (i = 1; i<= length(colors); ++i) {
    width = fields[i + 1] - fields[i] < 0 ? length($0) : fields[i + 1] - fields[i]
    total += width
    printf "%s%s%s", colors[i], substr($0, fields[i], width), reset
  }

printf "%s\n", substr($0, total + 1)
}
/^$/ {
header = 1
}
'
}

_fzf_complete() {
  setopt localoptions ksh_arrays
  # Split arguments around --
  local args rest str_arg i sep
  args=("$@")
  sep=
  for i in {0..${#args[@]}}; do
    if [[ "${args[$i]}" = -- ]]; then
      sep=$i
      break
    fi
  done
  if [[ -n "$sep" ]]; then
    str_arg=
    rest=("${args[@]:$((sep + 1)):${#args[@]}}")
    args=("${args[@]:0:$sep}")
  else
    str_arg=$1
    args=()
    shift
    rest=("$@")
  fi

  local fifo lbuf cmd matches post
  fifo="${TMPDIR:-/tmp}/fzf-complete-fifo-$$"
  lbuf=${rest[0]}
  cmd=$(__fzf_extract_command "$lbuf")
  post="${funcstack[1]}_post"
  type $post > /dev/null 2>&1 || post=cat

  _fzf_feed_fifo "$fifo"
  matches=$(FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_COMPLETION_OPTS $str_arg" __fzf_comprun "$cmd" "${args[@]}" -q "${(Q)prefix}" < "$fifo" | $post | tr '\n' ' ')
  if [ -n "$matches" ]; then
    echo "$matches"
  fi
  command rm -f "$fifo"
}
