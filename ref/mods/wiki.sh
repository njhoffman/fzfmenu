#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SRC="${BASH_SOURCE[0]}"

FZF_MODES=('titles' 'tags' 'global')
FZF_MODE="${FZF_DEFAULT_MODE:-1}"

declare -A FZF_ACTIONS
FZF_ACTIONS[mdcat]="mdcat markdown output"
FZF_ACTIONS[mdcat:page]="mdcat markdown output paged"
FZF_ACTIONS[mdless]="mdless markdown output"
FZF_ACTIONS[mdless:page]="mdless markdown output paged"
FZF_ACTIONS[vimcat]="vimcat pandoc.markdown output"
FZF_ACTIONS[vimcat:page]="vimcat pandoc.markdown output paged"
FZF_ACTIONS[glow]="glow output of markdown file"
FZF_ACTIONS[glow:page]="glow output of markdown file paged"
FZF_ACTIONS[lookatme]="lookatme presentation"

FZF_ACTIONS_SORT=(
  "mdcat"
  "mdcat:page"
  "mdless"
  "mdless:page"
  "vimcat"
  "vimcat:page"
  "glow"
  "glow:page"
  "lookatme"
  "cat:id"
  "cat:preview"
  "yank:id"
  "yank:preview"
)

FZF_TMUX_OPTS="-w80 "

function print_line {
  declare -A clr
  lc=$'\e[' rc=m
  clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
  clr[icon]="${lc}${CLR_ICON:-38;5;4}${rc}"
  clr[cli_icon]="${lc}${CLR_CLI_ICON:-38;5;4}${rc}"
  clr[lang_icon]="${lc}${CLR_LANG_ICON:-38;5;4}${rc}"
  clr[desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
  clr[date]="${lc}${CLR_DATE:-38;5;238;3}${rc}"
  clr[lines]="${lc}${CLR_LINES:-38;5;24;3}${rc}"
  clr[rst]="${lc}0${rc}"

  # add view headers command, other icons? lang, cli, devhints, learninx
  # add frecency scores, size info, last accessed info, headers info
  #         ﴲ      ﰮ    襁      練                ﲀ  ﳤ      
  md_icon="${clr[icon]} ${clr[rst]}"
  cli_icon="${clr[cli_icon]} ${clr[rst]}"
  lang_icon="${clr[lang_icon]} ${clr[rst]}"
  base_dir="$HOME/zettelkasten"

  title="$1"
  path="${base_dir}/${2#\./}"
  icon="$md_icon"
  lines=$(wc -l "$path" 2>/dev/null | cut -f1 -d' ')
  lines="${clr[lines]}${lines}L${clr[rst]}"
  create_diff=$(stat --format '%x' "${path}")
  # %x, %y, %w
  if [[ $title =~ "(cli)" ]]; then
    title="${title#\(cli\) }"
    icon="$cli_icon"
  elif [[ $title =~ "(lang)" ]]; then
    title="${title#\(lang\) }"
    icon="$lang_icon"
  fi
  lines="$(printf "%20s\n" $lines)"
  create_diff="$(printf "%25s\n" $create_diff)"
  create_diff="${clr[date]}$(rel_fmt $create_diff)${clr[rst]}"
  printf "%s %s %-50.50s %25s %25s\n" \
    "$path" "$icon" "$title" "$lines" "$create_diff"
}

function wiki_titles {
  neuron='LC_ALL=C neuron -d ~/zettelkasten query --zettels'
  while IFS=$'\n' read -r line; do
    fields=".Title,.Path"
    IFS=$'\n' read -r -d '' title path \
      <<<$(echo "$line" | jq -r "$fields") || true
    title_len=${#title}
    title="$(echo $title | emojify)"
    title_len=$((${#title} - title_len))
    printf -v pad %${title_len}s
    print_line "$title$pad" "$path"
  done <<<$(eval "$neuron" 2>/dev/null | jq -c '.[]') \
    || true
  # | column -s' ' -t \
}

function wiki_tags {
  neuron='LC_ALL=C neuron -d ~/zettelkasten query --zettels'
  while IFS=$'\n' read -r line; do
    # fields=".ID,.Title,.Meta.tags[],.Date,.Path"
    fields=".ID,.Title,.Date,.Path,.Meta.tags[]"
    IFS=$'\n' read -r -d '' id title date path tags \
      <<<$(echo "$line" | jq -r "$fields") || true
    printf "%s|%s|%s|%s\n" "$id" "$title" "$date" "$path"
  done <<<$(eval "$neuron" | jq -c '.[]') \
    | column -s'|' -t \
    | cut -c -$(($(tput cols) - 1)) \
    || true
}

function wiki_global {
  echo -e "wiki global \nwiki global2"
}

function fzf_results {
  action="$1" && shift
  items=($@)
  # echo "echo 'Performing $action on ${items[*]}'"
  for item in "${items[@]}"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    debug "$action: $item"
    case "$action" in
      'mdcat') $HOME/.asdf/shims/mdcat "${item}" ;;
      'mdcat:page') $HOME/.asdf/shims/mdcat -p "${item}" ;;
      'mdless') $HOME/.asdf/shims/mdless --theme nick "${item}" ;;
      'mdless:page') $HOME/.asdf/shims/mdless -p --theme nick "${item}" ;;
      'glow') $HOME/.nix-profile/bin/glow "${item}" ;;
      'glow:page') $HOME/.nix-profile/bin/glow -p "${item}" ;;
      'vimcat')
        vimargs="colorscheme nord-nick | hi! Error guifg=#dd2222 guibg=none"
        vimargs="${vimargs} | set filetype=markdown.pandoc | set conceallevel=3 | set termguicolors"
        /usr/local/bin/nvimpager -c -- -c "${vimargs}" "${item}"
        ;;
      'vimcat:page')
        vimargs="colorscheme nord-nick | hi! Error guifg=#dd2222 guibg=none"
        vimargs="${vimargs} | set filetype=markdown.pandoc | set conceallevel=3 | set termguicolors"
        /usr/local/bin/nvimpager -p -- -c "${vimargs}" "${item}"
        ;;
      'lookatme')
        cat "${item}" \
          | pcregrep -Mvi "(?s)^---.*^---" \
          | /usr/bin/lookatme "${item}"
        ;;
      *) fzf_result_default "$action" "${item}" ;;
    esac
  done
}

function fzf_command {
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $(fzf_options)"
  mode-display-hints
  if [[ $FZF_MODE -eq 1 ]]; then
    wiki_titles
  elif [[ $FZF_MODE -eq 2 ]]; then
    wiki_tags
  else
    wiki_global
  fi
}

function fzf_preview() {
  # mode="$1" && shift
  mode_name="${FZF_MODES[$((FZF_MODE - 1))]}"
  selection="$1"
  case "$mode_name" in
    titles | tags)
      mdless --theme "nick" $selection
      ;;
    global)
      echo "global $selection"
      ;;
  esac
}

function fzf_options {
  opts="\
  --header-lines=1
  --preview-window='hidden:nowrap'
  --delimiter=' '
  --with-nth=2..
  --nth=3"
  echo "${opts}"
}

FZF_DEFAULT_COMMAND="$SRC --command"
source "../fzf.sh"
