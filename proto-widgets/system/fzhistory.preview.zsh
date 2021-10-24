#!/usr/bin/env zsh

function _fzhistory-preview() {
  HISTDB_FILE=$1
  local where="(history.id == '$(sed -e "s/'/''/g" <<< "$2" | tr -d '\000')')"

  local cols="
    history.id as id,
    commands.argv as argv,
    max(start_time) as max_start,
    exit_status,
    duration as secs,
    count() as runcount,
    history.session as session,
    places.host as host,
    places.dir as dir"

  local query="
    select
      strftime('%d/%m/%Y %H:%M', max_start, 'unixepoch', 'localtime') as time,
      exit_status,
      secs,
      host,
      dir,
      session,
      argv as cmd
    from
      (select ${cols}
      from
        history
        left join commands on history.command_id = commands.id
        left join places on history.place_id = places.id
      where ${where})
  "

  array=("${(@f)$(sqlite3 -cmd ".timeout 1000" "${HISTDB_FILE}" -separator "
" "$query" )}")
  # Add some color
  if [[ ! ${array[2]} ]];then
    #Color exitcode red if not 0
    array[2]=$(echo "\033[31m${array[2]}\033[0m")
  fi
  if [[ ${array[3]} -gt 300 ]];then
    # Duration red if > 5 min
    array[3]=$(echo "\033[31m${array[3]}\033[0m")
  elif [[ ${array[3]} -gt 60 ]];then
    # Duration yellow if > 1 min
    array[3]=$(echo "\033[33m${array[3]}\033[0m")
  fi
  printf "\033[1mLast run\033[0m\n\nTime:      %s\nStatus:    %s\nDuration:  %s sec.\nHost:      %s\nDirectory: %s\nSessionid: %s\nCommand:\n\n\t\033[1m%s\n\033[0m" $array
}
