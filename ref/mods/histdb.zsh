#!/bin/zsh

source $HOME/.zinit/plugins/larkery---zsh-histdb/sqlite-history.zsh

NL="
"
declare -A clr
lc=$'\e[' rc=m
clr[nonzero]="${lc}${CLR_NONZERO_EXIT:-38;5;1;3}${rc}"
clr[rst]="${lc}0${rc}"

get_date_format() (
  echo "%m/%d"
)

histdb-fzf-query(){
  # A wrapper for histb-query with fzf specific options and query
  _histdb_init
  local -a opts

  # overwrite
  local session="${HISTDB_PSESSION:-$HISTDB_SESSION}"

  zparseopts -E -D -a opts s d t
  local where=""
  local everywhere=0
  for opt ($opts); do
    case $opt in
      -s)
        where="${where:+$where and} session in (${session})"
        ;;
      -d)
        where="${where:+$where and} (places.dir like '$(sql_escape $PWD)%')"
        ;;
      -t)
        everywhere=1
        ;;
    esac
  done

  if [[ $everywhere -eq 0 ]];then
    where="${where:+$where and} places.host=${HISTDB_HOST}"
  fi

  local cols="history.id as id, commands.argv as argv, max(start_time) as max_start, exit_status"

  local date_format="$(get_date_format)"
  local mst="datetime(max_start, 'unixepoch')"
  local dst="datetime('now', 'start of day')"
  local yst="datetime('now', 'start of year')"
  local timecol="strftime(
    case when $mst > $dst then '%H:%M'
    else (
      case when $mst > $yst then
        '${date_format}'
      else
        '${date_format}/%Y'
      end)
    end,
    max_start,
    'unixepoch',
    'localtime') as time"

  local query="
    select
      id,
      ${timecol},
      CASE exit_status WHEN 0 THEN '' ELSE '${clr[nonzero]}' END || replace(argv, '$NL', ' ') as cmd,
        CASE exit_status WHEN 0 THEN '' ELSE '${clr[rst]}' END
        from (
          select ${cols} from history
          left join commands on history.command_id = commands.id
          left join places on history.place_id = places.id
          ${where:+where ${where}}
          group by history.command_id, history.place_id
          order by max_start desc
        )
      order by max_start desc"

  # use Figure Space U+2007 as separator
  _histdb_query -separator ' ' "$query"
}

histdb-fzf-query $@
