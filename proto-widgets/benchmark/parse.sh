#!/bin/bash

infile="cpu_list.html"
outfile="cpu_list.txt"
i=0
output=""
line=""
while read -r col; do
  if [[ $i -eq 0 ]]; then
    line="$col"
    i=$((i + 1))
  elif [[ $i -eq 4 ]]; then
    line="${line}|${col}"
    output="${output}\n${line}"
    line=""
    i=0
  else
    line="${line}|${col}"
    i=$((i + 1))
  fi
done < <(cat "$infile" | pup '#cputable tr td text{}')
printf "$output %s\n" > "$outfile"
