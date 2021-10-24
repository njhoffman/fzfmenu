
fzf-history() {
  local res=($(fc -rl 1 \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
      --query=${(qqq)LBUFFER}
      -n2..,..
      --tiebreak=index
      --bind=${ZSH_FZF_PASTE_KEY}:accept
      --bind=\"${ZSH_FZF_EXEC_KEY}:execute@echo -\$(echo {} | sed -e 's/^ //')@+abort\"
      " ${=FZF_CMD}))
  if [ -n "$res" ]; then
    local num=$res[1]
    if [ -n "$num" ]; then
      if [ $num -ge 1 ]; then
        zle vi-fetch-history -n $num
        zle reset-prompt
      else
        zle vi-fetch-history -n ${num#-}
        zle accept-line
      fi
    fi
  fi
}
zle -N fzf-history
