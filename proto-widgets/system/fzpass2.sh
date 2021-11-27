#!/usr/bin/env bash
# -*- +indent: 2 -*-
# Fuzzy select a password from the [[https://wiki.archlinux.org/index.php/Pass][pass]] password manager.
#
# A fzf command used to interactively select files in your local password
# store and present them to you. On selection the associated password file
# is decrypted and inserted into your PAGER. The first line is also copied
# to your clipboard.

fzpass2() {
  local list_only=0 color=1
  IFS=: read -r -d '' USAGE <<-EOF
Usage: fzpass [-h] [-l] [-C]
  Interactively select and act upon password records
Options:
 -h    Print this help message and exit
 -l    Only list records instead of running fzf
 -C    Disable coloring of directories/files
EOF
  while getopts 'lhC' OPTION; do
    case "$OPTION" in
      l) list_only=1 ;;
      C) color=0 ;;
      h)  echo -n "$USAGE"; return 0 ;;
      \?) echo -n "$USAGE" >&2; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # shellcheck disable=SC2016
  local fzf_args=( --ansi
                   --bind 'ctrl-m:execute:
                             passout=$(pass {}) || exit 1
                             pass show {} --clip=1 >/dev/null
                             echo "$passout" | preview -l yaml - | $PAGER'
                   --bind 'alt-e:execute:pass edit {}'
                   --bind 'ctrl-y:execute-silent:
                             pass show {} --clip=1'
                   --preview 'pass {} | preview -l yaml -'
                   --preview-window :hidden )
  [ -z "$*" ] || fzf_args+=( -q "$*" )

  local root=${PASSWORD_STORE_DIR:-$HOME/.pass}
  find -L "$root" -mindepth 1 \
       \( -iname '.*' -and -prune \) -or \
       -type f -iname '*.gpg' -printf '%h:%f\n' |
    # We color code directories and files independently.
    gawk -F : \
         -v root="$root" \
         -v color_dir=$'\e[33m' \
         -v color_file='' \
         -v color_reset=$'\e[0m' \
         -v color="$color" \
         -e 'BEGIN { if (!color) { color_dir=""; color_file=""; color_reset=""; } }' \
         -e '{
  sub(root "/?", "", $1)
  if ($1) {
    printf("%s", color_dir $1 "/" color_reset)
  }
  sub(/.gpg$/, "", $2)
  printf("%s\n", color_file $2 color_reset)
}' |
    if [ "$list_only" -ne 0 ]; then
      cat
    else
      fzf "${fzf_args[@]}"
    fi
}

fzpass2
