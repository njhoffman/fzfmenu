#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

COLORS_JSON="$CWD/colors-255.json"
COLORS_TXT="$CWD/colors-255.txt"
COLORS_DETAIL="$CWD/colors-names.txt"

# answer=$(( ($numerator + ($denominator - 1) / $denomonator))

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
}

# to parse original json into flat text
_fzf-source-json() {
  while read -r line; do
    fields=".colorId, .name, .hexString, .rgb.r, .rgb.g, .rgb.b, .hsl.h, .hsl.s, .hsl.l"

    IFS=$'\n' read -r -d '' colorId name hexString r g b h s l  \
      <<< "$(echo $line | jq -r $fields)"

    printf "%s\t%s\t%s\trgb(%s,%s,%s)\thsl(%s,%s,%s)\n" \
      "$colorId" "$name" "$hexString" $r $g $b ${h%.*} $s $l

  done < <(cat $COLORS_JSON | jq -c '.[]')
}

_fzf-command() {
  read -r -d '' cmd <<'EOF'
  while read -r line; do
    printf "%s\\n" "$line" | \\
      awk '{
        printf "\\033[38;5;%sm  \\033[0m \\t%s \\t", $1, $1, $1
        printf "\\033[38;5;%sm%s\\033[0m \\t%s \\t%s \\t%s\\n", $1, $2, $3, $4, $5
      }'
  done < <(cat ~/git/fzfmenu/widgets/development/colors-255.txt) | column -t -s $'\\t'
EOF

  echo "${cmd}"

  # while read -r line; do
  #   printf "%s\n" "$line" | \
  #     awk '{
  #       printf "\033[38;5;%sm  \033[0m \t%s \t", $1, $1, $1
  #       printf "\033[38;5;%sm%s\033[0m \t%s \t%s \t%s\n", $1, $2, $3, $4, $5
  #     }'
  # done < <(cat $COLORS_TXT) | column -t -s $'\t'
}

_fzf-extra-opts() {
  echo "--with-nth=2.. --nth=2,3"
}

_fzf-result() {
  echo -e "one\two\three"
}

_fzf-prompt() {
  echo "colors❯ "
}

_fzf-preview() {
  echo "These are my colors: $1"
}

# _fzf-command
source "$FZF_LIB.zsh"
