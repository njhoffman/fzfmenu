#!/bin/bash

find * | fzf --prompt 'All> ' \
  --header 'CTRL-D: Directories / CTRL-F: Files' \
  --bind 'ctrl-d:change-prompt(Directories> )+reload(find * -type d)' \
  --bind 'ctrl-f:change-prompt(Files> )+reload(find * -type f)'
