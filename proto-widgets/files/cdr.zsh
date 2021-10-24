#!/bin/zsh

# https://github.com/zsh-users/zsh/blob/master/Functions/Chpwd/cdr
fzf-cdr() {
  local dir=$(cdr -l \
    | sed 's/^[^ ][^ ]*  *//' \
    | while read f
      do
        f="${f/#\~/$HOME}"
        [ -d "${f}" ] \
          && echo "${f}" \
          || echo -e "\e[31m$f\e[m"
      done \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
      --bind=\"${ZSH_FZF_PASTE_KEY}:execute@echo {}@+abort\"
      --bind=\"${ZSH_FZF_EXEC_KEY}:execute@echo 'cd {}'@+abort\"
      " ${=FZF_CMD})
  if [[ -n "$dir" ]]; then
    if [[ "$dir" =~ '^cd (.+)$' ]]
    then
      ${=dir}
      zle reset-prompt
    else
      LBUFFER="${LBUFFER}${dir}"
      zle redisplay
    fi
  fi
}
zle -N fzf-cdr
