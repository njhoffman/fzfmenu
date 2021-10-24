#!/bin/zsh

__fzfcmd() {
  [ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

_fzf_file-widget() {
  LBUFFER="${LBUFFER}$(__fsel)"
  local ret=$?
  # zle reset-prompt
  return $ret
}
zle     -N   _fzf_file-widget
# bindkey '^T' fzf-file-widget


_fzf_cd-widget() {
  local target=". ${1:-}"
  local default_cmd="command find -L $target -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | cut -b3-"

  local cmd="${default_cmd}"
  if [[ -n "$FZF_ALT_C_COMMAND" ]]; then
    cmd="${FZF_ALT_C_COMMAND} $target"
  fi

  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m)"
  if [[ -z "$dir" ]]; then
    # zle redisplay
    return 0
  fi
  # zle push-line # Clear buffer. Auto-restored on next prompt.
  BUFFER="cd ${(q)dir}"
  # zle accept-line
  local ret=$?
  unset dir # ensure this doesn't end up appearing in prompt expansion
  # zle reset-prompt
  return $ret
}
zle     -N    _fzf_cd-widget

_fzf_cd-widget "$@"
