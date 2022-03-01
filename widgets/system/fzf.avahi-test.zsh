#!/bin/zsh

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

function _fzf_command {
  declare -A _clr
  local lc=$'\e[' rc=m
  _clr[rst]="${lc}0${rc}"

  # avahi-browse \
  #   --all \
  #   --parsable \
  #   --resolve 2>/dev/null
  headers="_;Interface;Protocol;Name;Type;Domain;Address;IP;Port;Attr"
  fields="active iface prot name type domain host ip port attr"
  while read -r line; do
    IFS=';' read -r  active iface prot name net_type domain host ip attrs \
      <<< $(echo $line | tr -cd '\11\12\15\40-\176')
    printf "%s|%s|%s|%s|%s\n" $active $iface $net_type $name $ip
  done <<< $(printf "%s\n" $headers && cat ./avahi.txt) \
    | FS="\|" _fzf_tabularize $_clr[rst]{,,,,,} | fzf-tmux -p80%
    # | column -s'\|' -t  \
    # | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --preview 'echo {} |  hexyl'" fzf-tmux -p80% \

  # cat ./avahi.txt | cut -d';' -f2,7 | column -s';' -t

}


# 1: = resolved, + active, - inactive
# 2: wlx00c0ca35dbc6
# 3: IPv4 | IPv6
# 4: LyricStat2E107F
# 5: _iri._tcp | Microsoft Windows Network | Device Info
# 6: local
# 7: LyricStat2E107F.local
# 8: 192.168.1.67
# 9:  80
# 10: "CRC=45324" "lstsetupstep=1" "setupcomplete=YES" "modelname=LyricStat2E107F" "MAC=B82CA02E107F"

_fzf_command
