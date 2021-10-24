#!/bin/bash

PATH_HISTORY="$HOME/.config/chrome/Profiles-1/Default/History"
PATH_HISTORY_COPY="$HOME/.local/tmp/chrome_history.sql"
PATH_HISTORY_CSV="$HOME/.local/tmp/chrome_history.csv"

chrome_history() {
  local USER=`whoami`
  cp $PATH_HISTORY $PATH_HISTORY_COPY

  local SQL="
  SELECT
    url,
    title,
    DATETIME(last_visit_time / 1000000 + (strftime('%s', '1601-01-01') ), 'unixepoch', '+9 hours') AS date
    FROM
    urls
    GROUP BY
    title
    ORDER BY
    date DESC
    LIMIT
    10000
    ;
    "
    local SQL=$(echo "${SQL}" | tr '\n' ' ')

    expect -c "
    spawn sqlite3 $PATH_HISTORY_COPY
    expect \">\"
    send \".mode csv\r\"
    expect \">\"
    send \".output $PATH_HISTORY_CSV\r\"
    expect \">\"
    send \"$SQL\r\"
    expect \">\"
    " >/dev/null
  }

show_chrome_history() {
  local filter=${1:-""}
  local chrome_history=$(cat $PATH_HISTORY_CSV | tr -d '"')

  local select_history=$(
  echo ",,export\n$chrome_history" \
    | grep -P "(,,export|$filter)" \
    | awk -F ',' '!a[$2]++' \
    | awk -F ',' '{print $3"\t"$2}' \
    | tr -d "\r" \
    | fzf \
    | tr -d "\n"
  )

  if [ `echo $select_history | tr -d " "` = "export" ]; then
    echo "$chrome_history" \
      | grep "$filter" \
      | awk -F ',' '!a[$2]++' \
      | awk -F ',' '{print $3"\t"$2}' \
      | tr -d "\r"
          return
  fi

  if [ -n "$select_history" ]; then
    local title=`echo "$select_history" | awk -F '\t' '{print $1}'`
    local url=`echo "$chrome_history" | grep "$title"  | head -n 1 |awk -F ',' '{print $1}'`
    open $url
  fi
}


function show_by_date() {
  local chrome_history=$(cat $PATH_HISTORY_CSV | tr -d '"')
  # 表示したい日付を選択する
  local select_date=$(
  echo "$chrome_history" \
    | awk -F ',' '{print $3}' \
    | awk -F ' ' '{print $1}' \
    | grep -P '^[0-9]{4}-.*' \
    | sort -ur \
    | tr -d "\r" \
    | xargs -I {} gdate '+%Y-%m-%d (%a)' -d {} \
    | fzf \
    | awk -F '(' '{print $1}'
  )
  show_chrome_history $select_date
}

function main() {
  if [ "$1" = '-d' ]; then
    show_by_date
  else
    show_chrome_history $1
  fi
}

main $1
