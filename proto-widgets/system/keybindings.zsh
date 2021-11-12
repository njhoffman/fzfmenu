
() {
  local c
  for c in $@; do
    eval "fzf-g$c-widget() { local -r result=(\${(f)\"\$(_g$c)\"}); zle reset-prompt; LBUFFER+=\${(j: :)\${(q)result}} }"
    eval "zle -N fzf-g$c-widget"
    eval "bindkey '^g^$c' fzf-g$c-widget"
  done
} f b t r h s
@njhoffman
