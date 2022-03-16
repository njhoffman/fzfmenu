#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# https://api.stackexchange.com/docs/answers-by-ids#order=desc&sort=activity&ids=1732454&filter=!22E9KmxBIg.3eKO9CX1XP&site=stackoverflow
# https://api.stackexchange.com/2.3/answers/1732454?order=desc&sort=activity&site=stackoverflow&filter=!22E9KmxBIg.3eKO9CX1XP
# needs perl -> cpanm HTML::Entities
# https://api.stackexchange.com/docs/search
# https://api.stackexchange.com/docs/advanced-search
# https://api.stackexchange.com/questions/ids
# https://api.stackexchange.com/questions/ids/linked
# https://api.stackexchange.com/questions/ids/related
# Usage of /questions/{id}/favorite

# https://api.stackexchange.com/answers/ids
# Gets the set of answers identified by ids.
# This is meant for batch fetching of questions. A useful trick to poll for updates is to sort by activity, with a minimum date of the last time you polled.
# {ids} can contain up to 100 semicolon delimited ids. To find ids programmatically look for answer_id on answer objects.

# Usage of /questions/{ids}/answers GET
# Gets the answers to a set of questions identified in id.
# This method is most useful if you have a set of interesting questions, and you wish to obtain all of their answers at once or if you are polling for new or updates answers (in conjunction with sort=activity).

SRC="${BASH_SOURCE[0]}"

declare -A clr
lc=$'\e[' rc=m
clr[icon_answered]="${lc}${CLR_ICON_STAR:-38;5;220}${rc}"
clr[icon_unanswered]="${lc}${CLR_ICON_EYE:-38;5;240}${rc}"
clr[icon_views]="${lc}${CLR_ICON_FORK:-38;5;111}${rc}"
clr[views]="${lc}${CLR_ICON_FORK:-38;5;111}${rc}"
clr[answers]="${lc}${CLR_ICON_FORK:-38;5;111}${rc}"
clr[age]="${lc}${CLR_ICON_FORK:-38;5;111}${rc}"
clr[rst]="${lc}0${rc}"

declare -A FZF_ACTIONS
FZF_ACTIONS[clone]="clone with ghq"
FZF_ACTIONS[fetch]="download files to temp directory"
FZF_ACTIONS[browse]="explore files in fzf"
FZF_ACTIONS_SORT=(
  "clone"
  "fetch"
  "browse"
  "cat:id"
  "cat:preview"
  "yank:id"
  "yank:preview"
)

base_site="https://api.stackexchange.com/2.3/search?"

function so_output {
  #                
  views="${clr[icon_views]}  ${clr[rst]}"

  while read -r line; do
    fields=".is_answered, .view_count, .answer_count, .score, .last_activity_date"
    fields="${fields}, .created_date, .question_id, .link, .title"

    IFS=$'\n' read -r -d '' is_answered view_count answer_count score \
      last_activity_date created_date question_id link title \
      <<<$(echo "$line" | jq -r "$fields") || true

    answered="${clr[icon_answered]}  ${clr[rst]}"
    if [[ ${is_answered} == "false" ]]; then
      answered="${clr[icon_unanswered]}  ${clr[rst]}"
    fi

    time_ago="-183d"
    # | recode html..ascii
    title=$(echo "$title" | perl -MHTML::Entities -pe 'decode_entities($_);' | emojify)

    printf "%2d %2s${answered} %4s${views} %-55.55s %-8s\n" \
      "$score" "$answer_count" "$view_count" "$title" "$time_ago"
  done <<<"$(cat stack.json | jq -c '.items[]')" || true

  # .has_more, .quote_max, quota_remaining

  params="pagesize=100"
  # params="${params}&fromdate=1625097600"
  # params="${params}&todate=1647302400"

  # simple ...
  params="${params}&intitle=buffers"
  params="${params}&tagged=linux"

  # detailed ...
  # /search/advanced?"
  # params="${params}&body=linux"
  # params="${params}&intitle=buffers"
  # params="${params}&q=buffers"

  params="${params}&order=desc"
  # activity, votes, creation, relevance
  params="${params}&sort=activity"
  params="${params}&site=stackoverflow"
}

function fzf_results {
  action="$1" && shift
  items=($@)
  # echo "echo 'Performing $action on ${items[*]}'"
  for item in "${items[@]}"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    # debug "$action: $item"
    case "$action" in
      *) fzf_result_default "$action" "${item}" ;;
    esac
  done
}

function fzf_preview() {
  mode_name="${FZF_MODES[$((FZF_MODE - 1))]}"
  selection="$1"
  case "$mode_name" in
    *) echo "so $selection" ;;
  esac
}

function fzf_options {
  opts="
  --delimiter=' '
  --preview-window='hidden:nowrap'"
  echo "${opts}"
}

function fzf_command {
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(fzf_options)"
  so_output # | column -s'|' -t #| cut -c -$(($(tput cols) - 1))
}

FZF_DEFAULT_COMMAND="$SRC --command"

fzf_command
# source "../fzf.sh"

# answered question fields:
# "is_answered": true,
# "view_count": 31415,
# "favorite_count": 1,
# "down_vote_count": 2,
# "up_vote_count": 3,
# "accepted_answer_id": 2,
# "answer_count": 1,
# "score": 1,

# {
#   "tags": [
#   "zsh",
#   "zsh-completion"
# ],
# "owner": {
#   "account_id": 91222,
#   "reputation": 2894,
#   "user_id": 250610,
#   "user_type": "registered",
#   "accept_rate": 81,
#   "profile_image": "https://www.gravatar.com/avatar/aee2bb3e08e94a3770ef192d7df06f65?s=256&d=identicon&r=PG",
#   "display_name": "MikeTheTall",
#   "link": "https://stackoverflow.com/users/250610/mikethetall"
# },
# "is_answered": false,
# "view_count": 29,
# "answer_count": 1,
# "score": 0,
# "last_activity_date": 1643098164,
# "creation_date": 1642984701,
# "question_id": 70827840,
# "content_license": "CC BY-SA 4.0",
# "link": "https://stackoverflow.com/questions/70827840/zsh-tab-completion-for-files-not-in-the-current-directory",
# "title": "Zsh: tab completion for files not in the current directory?"
# }
