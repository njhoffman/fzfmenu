#!/bin/zsh
awk_recipe='
  BEGIN {
    FS="- "
    OFS="\t\t"
  } /\([1|4]\)/
  {
    gsub(/\([0-9]\)/, "", $1);
    if (!seen[$0]++) { print }
  }
'
awk_recipe='
  BEGIN {FS=OFS="- "}
  /\([1|4]\)/
  {
    gsub(/\([0-9]\)/, "", $1);
      if (!seen[$0]++) { print }
  }
'
awk_recipe='
  BEGIN {FS="- ";OFS=" "}
  /\([1|4]\)/ {
    gsub(/\([0-9]\)/, "", $1)
    if (!seen[$0]++) { print color_id $1 reset "|" $2 }
  }
'

man -k . 2>/dev/null \
  | sort \
  | awk -v color_id="\033[1;34m" -v reset="\033[0m" $awk_recipe \
  | column -s'\|' -t
