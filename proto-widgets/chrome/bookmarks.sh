#!/bin/bash

# shorten folders
# "duplicates" mode
# cache time of last update
# find time of last visit
# C-d, C-e, *move*, enter opens

function chrome_bookmarks() {
  bookmarks_path="$HOME/.config/google-chrome/Default/Bookmarks"

  jq_script='
  def ancestors: while(. | length >= 2; del(.[-1,-2]));
  . as $in | paths(.url?) as $key | $in | getpath($key) | {name,url, path: [$key[0:-2] | ancestors as $a | $in | getpath($a) | .name?] | reverse | join("/") } | .path + "/" + .name + "\t" + .url'

  jq -r "$jq_script" < "$bookmarks_path" \
    | sed -E $'s/(.*)\t(.*)/\\1\t\x1b[36m\\2\x1b[m/g' \
    | fzf --ansi \
    | cut -d$'\t' -f2 \
    | xargs open
}

function surfraw_bookmarks() {
  selected="$(grep -E '^([[:alnum:]])' ~/.config/surfraw/bookmarks | sort -n | fzf -e -i -m --reverse | awk '{print $1}')"
  [ -z "$selected" ] && exit
  echo "$selected" | while read -r line; do  surfraw -browser="$BROWSER" "$line";  done
}

chrome_bookmarks
