#!/bin/zsh

SRC="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SRC" )" >/dev/null 2>&1 && pwd)"
FZF_HISTDB_FILE="${(%):-%N}"
HISTDB_FZF_LOGFILE="/tmp/fzf-histdb.log"
HISTDB_FZF_CMD=${HISTDB_FZF_COMMAND:-fzf}
HISTDB_SRC="$HOME/.zinit/plugins/larkery---zsh-histdb/sqlite-history.zsh"
FZF_LIB="$CWD/../../fzf-lib"
FZF_MODES=('session' 'location' 'host' 'global')
FZF_MODES_HIDE_KEYS=1

datecmd='date'

if [[ ! -x $(command -v "_histdb_init") ]]; then
  source $HISTDB_SRC
fi

# variables for substitution in log
NL="
"
NLT=$(printf "\n\t\t")

autoload -U colors && colors

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
      CASE exit_status WHEN 0 THEN '' ELSE '${fg[red]}' END || replace(argv, '$NL', ' ') as cmd,
        CASE exit_status WHEN 0 THEN '' ELSE '${reset_color}' END
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
  _fzf-log "query for log '${(Q)query}'"
  _histdb_query -separator ' ' "$query"
  _fzf-log "query completed"
}

histdb-get-command(){
  HISTDB_FILE=$1
  CMD_ID=$2

  local query="
    select
      argv as cmd
    from
      history
      left join commands on history.command_id = commands.id
    where
      history.id='${CMD_ID}'
  "
  printf "%s" "$(sqlite3 -cmd ".timeout 1000" "${HISTDB_FILE}" "$query")"
}

_fzf-prompt() {
  echo " zsh❯ "
}

_fzf-preview() {
  mode="$1" && shift
  local where="(history.id == '$(sed -e "s/'/''/g" <<< "$2" | tr -d '\000')')"

  local date_format="$(get_date_format)"

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
      strftime('${date_format}/%Y %H:%M', max_start, 'unixepoch', 'localtime') as time,
      ifnull(exit_status, 'NONE') as exit_status,
      ifnull(secs, '-----') as secs,
      ifnull(host, '<somewhere>') as host,
      ifnull(dir, '<somedir>') as dir,
      session,
      id,
      argv as cmd
    from
      (select ${cols}
      from
        history
        left join commands on history.command_id = commands.id
        left join places on history.place_id = places.id
      where ${where})
  "

  array_str=("${$(sqlite3 -cmd ".timeout 1000" "${HISTDB_FILE}" -separator " " "$query" )}")
  array=(${(@s: :)array_str})

  _fzf-log "DETAIL: ${array_str}"

  # Add some color
  if [[ "${array[2]}" == "NONE" ]];then
    #Color exitcode magento if not available
    array[2]=$(echo "\033[35m${array[2]}\033[0m")
  elif [[ ! ${array[2]} ]];then
    #Color exitcode red if not 0
    array[2]=$(echo "\033[31m${array[2]}\033[0m")
  fi
  if [[ "${array[3]}" == "-----" ]];then
    #Color duration magento if not available
    array[3]=$(echo "\033[35m${array[3]}\033[0m")
  elif [[ "${array[3]}" -gt 300 ]];then
    # Duration red if > 5 min
    array[3]=$(echo "\033[31m${array[3]}\033[0m")
  elif [[ "${array[3]}" -gt 60 ]];then
    # Duration yellow if > 1 min
    array[3]=$(echo "\033[33m${array[3]}\033[0m")
  fi

  printf "\033[1mLast run\033[0m\n\nTime:      %s\nStatus:    %s\nDuration:  %s sec.\nHost:      %s\nDirectory: %s\nSessionid: %s\nCommand id: %s\nCommand:\n\n" ${array[0]}  ${array[1]}  ${array[2]}  ${array[3]} ${array[4]} ${array[5]} ${array[6]} ${array[7]}
  echo "${array[8,-1]}"
}

_fzf-extra-opts() {
  opts=""
  delimiter=0x2007
  opts="${opts} --delimiter=' ' --nth=2.. --with-nth=2.."
  echo "${opts}"
}

_fzf-source() {
  mode="${1:-1}" && shift

  _fzf-log "$HISTDB_HOST: mode changed to ${FZF_MODES[$mode]} ($mode)"
  case "$FZF_MODES[$mode]" in
    'session')
      cmd_opts="-s"
      ;;
    'location')
      cmd_opts="-d"
      ;;
    'host')
      cmd_opts=""
      ;;
    'global')
      cmd_opts="-t"
      ;;
  esac

  histdb-fzf-query ${cmd_opts}
  # _fzf-log "histdb-get-command ${HISTDB_FILE} ${fzf_selected}"
  # selected=$(histdb-get-command ${HISTDB_FILE} ${fzf_selected})
  # _fzf-log "selected = $selected"
  # _fzf-log "=================== DONE ==================="
}

source "${FZF_LIB}.zsh"
