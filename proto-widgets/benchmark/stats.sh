#!/bin/bash

infile="cpu_list.txt"
outfile="cpu_list.data"
min=(0 0 0 0)
max=(0 0 0 0)
mean=(0 0 0 0)
n=(0 0 0 0)
i=0
while read -r line; do
  # IFS=$'\n' read -r -d '' name mark rank value price \
  #   done <<< "$(echo -e "$line" | sed 's/,//g' | sed 's/|/\n/g')"
  # printf "%s %s %s %s %s\n" "$name" "$mark" "$rank" "$value" "$price"
  j=0
  printf "\r%10s%s" "$i" "$line"
  while read -r col; do
    if [[ $j -gt 0 && $col != "NA" ]]; then
      col=$(echo "$col" | sed 's/[,]//g')
      [[ $j -gt 2 ]] && col=$(bc <<< "$col * 100" | sed 's/.00$//g')
      [[ ${max[j - 1]} -lt $col ]] && max[j - 1]=$col
      [[ ${min[j - 1]} -gt $col || ${min[j - 1]} -eq 0 ]] && min[j - 1]=$col
      mean[j - 1]=$((mean[j - 1] + col))
      n[j - 1]=$((n[j - 1] + 1))
    fi
    [[ $j -lt 4 ]] && j=$((j + 1)) || j=0
  done < <(echo -e "$line" | sed 's/[\$\*]//g' | sed 's/|/\n/g')
  i=$((i + 1))
done < <(cat "$infile")

for i in {0..3}; do
  mean[i]=$((mean[i] / n[i]))
done

printf "%s " "${min[@]}" > "$outfile"
printf "\n" >> "$outfile"
printf "%s " "${max[@]}" >> "$outfile"
printf "\n" >> "$outfile"
printf "%s " "${mean[@]}" >> "$outfile"
