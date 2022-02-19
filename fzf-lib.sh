#!/bin/bash

_fzf_tabularize() {
  if [[ $# = 0 ]]; then
    cat
    return
  fi

  awk \
    -v FS=${FS:- } \
    -v colors_args="$*" \
    -v reset="\033[0m" '
  BEGIN { split(colors_args, colors, " ") }
  {
    str = $0
    for (i = 1; i <= length(colors); ++i) {
      field_max[i] = length($i) > field_max[i] ? length($i) : field_max[i]
      fields[NR, i] = $i
      pos = index(str, FS)
      str = substr(str, pos + 1)
    }
    if (pos != 0) {
      fields[NR, i] = str
    }
  }
  END {
    for (i = 1; i <= NR; ++i) {
      for (j = 1; j <= length(colors); ++j) {
        printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), colors[j], fields[i, j], reset
      }
      if ((i, j) in fields) {
        printf "  %s", fields[i, j]
      }
      printf "\n"
    }
  }
'
}

_fzf_tabularize_header() {
  if [[ $# = 0 ]]; then
    cat
    return
  fi
  header="$1"
  shift

  awk \
    -v FS=${FS:- } \
    -v header="$header" \
    -v colors_args="$*" \
    -v reset="\033[0m" '
  BEGIN { split(colors_args, colors, " ") }
  {
      str = $0
      for (i = 1; i <= length(colors); ++i) {
        field_max[i] = length($i) > field_max[i] ? length($i) : field_max[i]
        fields[NR, i] = $i
        pos = index(str, FS)
        str = substr(str, pos + 1)
      }
      if (pos != 0) {
        fields[NR, i] = str
      }
  }
  END
  {
      for (i = 1; i <= NR; ++i) {
        for (j = 1; j <= length(colors); ++j) {
          if (i == 1) {
            printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), header, fields[i, j], reset
          } else {
          printf "%s%s%-" field_max[j] "s%s", (j > 1 ? "  " : ""), colors[j], fields[i, j], reset
        }
      }
      printf "\n"
    }
  }
'
}
