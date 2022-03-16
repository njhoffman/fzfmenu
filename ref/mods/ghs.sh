#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SRC="${BASH_SOURCE[0]}"

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
  # mode_name="${FZF_MODES[$((FZF_MODE - 1))]}"
  selection="$1"
  echo "ghs $selection"
  # case "$mode_name" in
  #   *) echo "ghs $selection" ;;
  # esac
}

function fzf_options {
  opts="
  --delimiter=' '
  --preview-window='hidden:nowrap'"
  echo "${opts}"
}

function fzf_command {
  ghs_rate_limit

  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(fzf_options)"
  # setterm --linewrap off
  ghs_output # | column -s'|' -t #| cut -c -$(($(tput cols) - 1))
  # setterm --linewrap on
}

FZF_DEFAULT_COMMAND="$SRC --command"
source "ghs.init.sh"
source "../fzf.sh"

# 'cc':           '',
# 'clj':          '',
# 'cljc':         '',
# 'coffee':       '',
# 'conf':         '',
# 'cp':           '',
# 'cs':           '',
# 'csh':          '',
# 'cxx':          '',
# 'd':            '',
# 'dart':         '',
# 'db':           '',
# 'diff':         '',
# 'dump':         '',
# 'edn':          '',
# 'eex':          '',
# 'ejs':          '',
# 'erl':          '',
# 'ex':           '',
# 'exs':          '',
# 'f#':           '',
# 'fish':         '',
# 'fs':           '',
# 'fsi':          '',
# 'fsscript':     '',
# 'fsx':          '',
# 'gif':          '',
# 'go':           '',
# 'h':            '',
# 'haml':         '',
# 'hbs':          '',
# 'hh':           '',
# 'hpp':          '',
# 'hrl':          '',
# 'hs':           '',
# 'htm':          '',
# 'hxx':          '',
# 'ico':          '',
# 'ini':          '',
# 'jl':           '',
# 'jpeg':         '',
# 'jpg':          '',
# 'json':         '',
# 'jsx':          '',
# 'ksh':          '',
# 'leex':         '',
# 'less':         '',
# 'lhs':          '',
# 'mdx':          '',
# 'mjs':          '',
# 'ml':           'λ',
# 'mli':          'λ',
# 'mustache':     '',
# 'nix':          '',
# 'php':          '',
# 'pl':           '',
# 'pm':           '',
# 'png':          '',
# 'pp':           '',
# 'ps1':          '',
# 'psb':          '',
# 'psd':          '',
# 'pyc':          '',
# 'pyd':          '',
# 'pyo':          '',
# 'rake':         '',
# 'rlib':         '',
# 'rmd':          '',
# 'rproj':        '鉶',
# 'rs':           '',
# 'rss':          '',
# 'sass':         '',
# 'scala':        '',
# 'slim':         '',
