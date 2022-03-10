#!/bin/bash

# TODO: implement modes with reload function
# dir mode, file mode, all mode, frecency mode
# curr dir, home dir, goto dir, increment mode

fd --hidden --follow --no-ignore-vcs . "$HOME" | prettyfile \
  | fzf --prompt 'All> ' \
    --with-nth=2.. \
    --delimiter='\|' \
    --header 'CTRL-D: Directories / CTRL-F: Files' \
    --bind 'ctrl-d:change-prompt(Directories> )+reload(fd --type d --full-path . ~ | prettyfile)' \
    --bind 'ctrl-f:change-prompt(Files> )+reload(fd --type f --full-path . ~ | prettyfile)'
