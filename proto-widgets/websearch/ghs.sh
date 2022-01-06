#!/bin/bash

# [].name:              hexo
# [].description:       A fast and simplel powerful blog freamework]
# [].full_name:         hexojs/hexo
# [].score:             1
# [].language:          C++
# [].size:              110358
# [].stargazers_count:  1497
# [].wacthers_count:    1497
# [].forks_count:       1497
# [].open_issues_count: 18

# │     "commits_url": "https://api.github.com/repos/hexpm/hex/commits{/sha}",                                                     │
# │     "git_commits_url": "https://api.github.com/repos/hexpm/hex/git/commits{/sha}",                                             │



# --sort=(stars|forks|updated), --in=(name|description|readme)
# ghs repositories --language=JavaScript --sort=stars hex

function output_all {
  echo "Name  FullName  Score  Language  Size  Stars  Watchers  Forks  Issues  Description"
  echo "----  --------  -----  --------  ----- -----  --------  -----  ------  -----------"
  while read -r line; do
    fields=".name, .full_name, .score, .language, .size, .stargazers_count"
    fields="${fields},.watchers_count, .forks_count, .open_issues_count, .description"

    IFS=$'\n' read -r -d '' name full_name score language size stars watchers forks issues description \
      <<< $(echo $line | jq -r "$fields")

  printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n" \
      $name $full_name $score $language $size $stars $watchers $forks $issues $description

  done <<< "$(cat ghs.json | jq -c '.[]')"
}

function output {
  while read -r line; do
    fields=".name, .full_name, .score, .language, .size, .stargazers_count"
    fields="${fields},.watchers_count, .forks_count, .open_issues_count, .description"

    IFS=$'\n' read -r -d '' name full_name score language size stars watchers forks issues description \
      <<< $(echo $line | jq -r "$fields")

  printf "%s|%s|%s|%s|%s|%s|%s\n" \
      $score $language $name $stars $forks $issues "${description[*]}"

  done <<< "$(cat ghs.json | jq -c '.[]')"
}

output | column -s'|' -t | cut -c -$(($(tput cols) -1))
# output | column -s'|' -t
