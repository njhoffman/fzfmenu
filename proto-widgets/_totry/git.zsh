

fzf-git-checkout() {
  [[ $(git status 2> /dev/null) ]] || return 0
  local branches=$(git branch -a --color=always | grep -v HEAD)
  local res=$(echo $branches \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
      --bind=\"${ZSH_FZF_PASTE_KEY}:execute@
        echo {} | sed -e 's/.* //' -e 's!remotes/[^/]*/!!'@+abort\"
      --bind=\"${ZSH_FZF_EXEC_KEY}:execute@
        echo git checkout \$(echo {} | sed -e 's/.* //' -e 's!remotes/[^/]*/!!')@+abort\"
      --query=${(qqq)LBUFFER}
      " ${=FZF_CMD})
  if [[ -n "$res" ]]; then
    if [[ "$res" =~ '^git checkout (.+)$' ]]
    then
      ${=res}
      zle reset-prompt
    else
      LBUFFER=$LBUFFER$res
      zle redisplay
    fi
  fi
}
zle -N fzf-git-checkout


fzf-git-log() {
  [[ $(git status 2> /dev/null) ]] || return 0
  local res=$(git log --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" \
  | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
    --no-sort
    --reverse
    --tiebreak=index
    --bind=\"${ZSH_FZF_PASTE_KEY}:execute@
      echo {} | grep -o '[a-f0-9]\\\{7\\\}' | head -1@+abort\"
    --bind=\"${ZSH_FZF_EXEC_KEY}:execute@
      git show --color=always \$(echo {} | grep -o '[a-f0-9]\\\{7\\\}' | head -1) \
      | less -R > /dev/tty@\"
    " ${=FZF_CMD})
  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER$res
    zle redisplay
  fi
}
zle -N fzf-git-log


fzf-git-status() {
  [[ $(git status 2> /dev/null) ]] || return 0
  local res=$(git -c color.status=always status -s \
  | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
    --no-sort
    --reverse
    --bind=\"${ZSH_FZF_PASTE_KEY}:execute@echo {} | sed -e 's/^...//'@+abort\"
    --bind=\"${ZSH_FZF_EXEC_KEY}:execute@
      f=\$(echo {} | sed -e 's/^...//')
      mark=\$(echo {} | grep -oP '^..')
      case \$mark in
        RM) echo \$f && echo && git diff --color=always \$(echo \$f | sed -e 's/^.* -> //') ;;
        R?) echo \$f ;;
        M?) git diff --color=always --cached \$f ;;
        ?M) git diff --color=always \$f ;;
        A? | ?D) git diff HEAD --color=always -- \$f ;;
        \\?\\?) cat \$f ;;
      esac | less -R > /dev/tty@\"
    " ${=FZF_CMD})
  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER$res
    zle redisplay
  fi
}
zle -N fzf-git-status
