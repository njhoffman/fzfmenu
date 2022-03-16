#!/bin/bash

declare -A clr
lc=$'\e[' rc=m
clr[icon_star]="${lc}${CLR_ICON_STAR:-38;5;220}${rc}"
clr[icon_eye]="${lc}${CLR_ICON_EYE:-38;5;240}${rc}"
clr[icon_fork]="${lc}${CLR_ICON_FORK:-38;5;111}${rc}"
clr[icon_issue]="${lc}${CLR_ICON_FORK:-38;5;111}${rc}"
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

GH_CACHE_FOLDER="$HOME/.local/share/gh-repos"
mkdir -p "$GH_CACHE_FOLDER"
#    
function get_devicon {
  lang="$1"
  declare -A iconmap
  iconmap[C++]=''
  iconmap[CoffeeScript]=''
  iconmap[CSS]=''
  iconmap[C]=''
  iconmap[Elixir]=''
  iconmap[Go]=''
  iconmap[Lua]=''
  iconmap[HTML]=''
  iconmap[JavaScript]=''
  iconmap[null]='' # 
  iconmap[Makefile]=''
  iconmap['Objective-C']=''
  iconmap['Objective-C++']=''
  iconmap[Python]=''
  iconmap[R]='ﳒ'
  iconmap[Rust]=''
  iconmap[SCSS]=''
  iconmap[Stylus]=' '
  iconmap[TeX]='ﭨ'
  iconmap[Java]=''
  iconmap[Markdown]=''
  iconmap[Ruby]=''
  iconmap[Shell]=''
  iconmap[Swift]=''
  iconmap[TypeScript]=''
  iconmap[Vim script]=''

  if [[ -v "iconmap[$lang]" ]]; then
    echo "${iconmap[$lang]}"
  else
    echo "$lang"
  fi
}


function output_all {
  # "created_at": "2020-07-23T13:07:27Z",
  # "updated_at": "2022-03-11T10:33:54Z",
  # "pushed_at": "2022-02-16T15:37:56Z",
  # "has_issues": true,
  # "has_projects": true,
  # "has_downloads": true,
  # "has_wiki": true,
  # "has_pages": false,
  # "archived": false,
  # "disabled": false,
  # "allow_forking": true,
  # "is_template": false,
  # "topics": [
  #   "notepad-plusplus-plugin"
  # ],
  # "visibility": "public",
  # "default_branch": "master",
  echo "Name  FullName  Score  Language  Size  Stars  Watchers  Forks  Issues  Description"
  echo "----  --------  -----  --------  ----- -----  --------  -----  ------  -----------"
  while read -r line; do
    fields=".name, .full_name, .score, .language, .size, .stargazers_count"
    fields="${fields},.watchers_count, .forks_count, .open_issues_count, .description"

    IFS=$'\n' read -r -d '' name full_name score language size stars watchers forks issues description \
      <<<"$(echo "$line" | jq -r "$fields")"

    printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n" \
      "$name" "$full_name" "$score" "$language" "$size" \
      "$stars" "$watchers" "$forks" "$issues" "$description"

  done <<<"$(cat ghs.json | jq -c '.[]')"
}

function ghs_rate_limit {
  data="$(gh api -X GET rate_limit | jq '.rate')"
  msg="$(echo $data | jq '.remaining') out of $(echo $data | jq '.limit')"
  msg="${msg} total requests remaining until $(echo $data | jq '.reset')"
  debug "$msg"

}

function ghs_output {
  fields=".id, .pushed_at, .name, .full_name, .score, .language, .size, .stargazers_count"
  fields="${fields},.watchers_count, .forks_count, .open_issues_count, .description"
  star="${clr[icon_star]} ${clr[rst]}"
  eye="${clr[icon_eye]} ${clr[rst]}"
  fork="${clr[icon_fork]}${clr[rst]}"
  issue="${clr[icon_issue]} ${clr[rst]}"


  while read -r line; do
    IFS=$'\n' read -r -d '' id pushed_at name full_name score language size \
      stars watchers forks issues description \
      <<<$(echo -e $line | jq -r "$fields") || true

    if [[ -n "$id" ]]; then
      cache_file="${GH_CACHE_FOLDER}/${id}.json"
      echo "$line" > "$cache_file"

      devicon="$(get_devicon "$language")"
      description="$(echo -e "${description[*]}" | emojify)"
      last_update="$(rel_fmt "$pushed_at")"

      printf "%s %-20.20s %6s ${star} %6s ${eye} %5s ${fork} %4s ${issue} %8s %s\n" \
        "$devicon" "$name" "$stars" "$watchers" \
        "$forks" "$issues" "$last_update" "${description}"
    fi

  done <<<"$(cat ./ghs2.json | jq -c '.items[]')"  || true

  # total_count=$(cat ./ghs2.json | jq '.total_count')

  # done <<<"$(\
  #   gh api -X GET search/repositories \
  #     -f per_page=100 \
  #     -f q='neovim' \
  #     -f language='' \
  #     | jq -c '.[]')" || true

}
