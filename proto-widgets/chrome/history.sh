#!/bin/bash

function chrome_history() {
  local cols sep google_history open

  cols=$((COLUMNS / 3))
  sep='{::}'

  google_history="$HOME/.config/google-chrome/Default/History"
  open=xdg-open

  cp -f "$google_history" /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url
  from urls order by last_visit_time desc" \
    | awk -F $sep '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' \
    | fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' \
    | xargs $open > /dev/null 2> /dev/null
}

chrome_history
