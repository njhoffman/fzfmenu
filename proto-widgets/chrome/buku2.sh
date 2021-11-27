#!/bin/bash

# BUKU bookmark manager
# get bookmark ids
get_buku_ids() {
  buku -p -f 5 | fzf --tac --layout=reverse-list -m | \
    cut -d $'\t' -f 1
      # awk -F= '{print $1}'
      # cut -d $'\t' -f 1
    }

# buku open
fb() {
  # save newline separated string into an array
  ids=( $(get_buku_ids) )

  echo buku --open ${ids[@]}

  [[ -z $ids ]] && return 1 # return error if has no bookmark selected

  buku --open ${ids[@]}
}

# buku update
fbu() {
  # save newline separated string into an array
  ids=( $(get_buku_ids) )

  echo buku --update ${ids[@]} $@

  [[ -z $ids ]] && return 0 # return if has no bookmark selected

  buku --update ${ids[@]} $@
}

# buku write
fbw() {
  # save newline separated string into an array
  ids=( $(get_buku_ids) )
  # print -l $ids

    # update websites
    for i in ${ids[@]}; do
      echo buku --write $i
      buku --write $i
    done
}

# fb - buku bookmarks fzfmenu opener
buku -p -f 4 |
    awk -F $'\t' '{
        if ($4 == "")
            printf "%s \t\x1b[38;5;208m%s\033[0m\n", $2, $3
        else
            printf "%s \t\x1b[38;5;124m%s \t\x1b[38;5;208m%s\033[0m\n", $2, $4, $3
    }' |
    ./fzmenu --tabstop 1 --ansi -d $'\t' --with-nth=2,3 \
        --preview-window='bottom:10%' --preview 'printf "\x1b[38;5;117m%s\033[0m\n" {1}' |
        awk '{print $1}' | xargs -d '\n' -I{} -n1 -r xdg-open '{}'
