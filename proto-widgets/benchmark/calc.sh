#!/bin/bash

statsfile="cpu_list.data"
default_input="Intel Core i7-1195G7 @ 2.90GHz|11079|843|2601|42600"
input="${1:-$default_input/}"

# P = (n/N) × 100, N = total results
# IFS=$'\n' read -r -d '' name mark rank value price \
#   done <<< "$(echo -e "$input" | sed 's/,//g' | sed 's/|/\n/g')"
# for i in {0..3}; do
#   percentiles[i]=""$(echo "${means[i]}" | sed 's/|/\n/g' | sort -n |
#     awk -v p="${!i}" '{a[NR]=$1}END{print a[int(NR*p/100+0.5)]}')"
# done

i=0
means=()
while read -r col; do
  means[i]=$col
  i=$((i + 1))
done < <(echo "$input" | sed 's/|/\n/g')

percentiles=(0 0 0 0)
i=0
while read -r col; do
  i=$((i + 1))
done <<< "$(cat "$statsfile" | tail -n1 | sed 's/ /\n/g')"

printf "%s\n" "${means[@]}"
printf "%s\n" "${percentiles[@]}"
#
# Intel Core i7-1195G7 @ 2.90GHz
#   Mark:   11,079 (84) (avg 7,313)
#   Rank:      843 (84) (avg 2,200)
#   Value:   26.01 (84) (avg 48.89)
#   Price: $426.00 (NA) (avg $440.12)
