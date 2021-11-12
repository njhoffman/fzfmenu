#!/bin/bash


URLREGEX='https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
GITURLREGEX='(git@|https:\/\/)([\w\.@]+)(\/|:)([\w,\-,\_]+)\/([\w,\-,\_]+)(.git){0,1}((\/){0,1})'


# Read input to tmp file for reuse
for reg in "${REGEXLIST[@]}"; do
  cat $inpfile | egrep -o $reg >> $tmpfile
done

cat $HOME/.local/share/nvim/tmux-butler/tmux-butler-stage1 \
  | egrep -n -o $URLREGEX \
  | tac \
  | sed 's/^\([0-9]\+\):/\1\t/g' \
  | uniq --skip-fields=1
