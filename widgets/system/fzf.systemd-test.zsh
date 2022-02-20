#!/bin/zsh

sudo "" 2>/dev/null

autoload -U colors
colors

# list-unit-files: 467
# list-units: 278 loaded
# list-units -all: 515 listed

systest() {
  systemctl_options=(--full --no-legend --no-pager --system --plain)
   # --ansi --tiebreak=index ${(Q)${(Z+n+)fzf_options}} ${(Q)${(Z+n+)${_fzf_complete_preview_systemctl_status/\$SYSTEMCTL_OPTIONS/$systemctl_options}}} ${(Q)${(Z+n+)FZF_DEFAULT_OPTS}} -- "$@" < \
   prefix=""
   # active (running) active(waiting) active(plugged) active(listening) active (exited)
   # inactive (dead)
   # service|socket|target|mount|device
   #          ⭘ ⏼  ○ ●
   local lc=$'\e[' rc=m
   clr_green1="${lc}${CLR_ID:-38;5;30}${rc}"

   cat < \
      <({
          systemctl list-units ${(Q)${(Z+n+)systemctl_options}} "$prefix*"
          systemctl list-unit-files ${(Q)${(Z+n+)systemctl_options}} "$prefix*"
      } |
          LC_ALL=C sort -b -f -k 1,1 -k 3,3r |
          awk \
              -v green=${fg[green]} \
              -v red=${fg[red]} \
              -v reset=$reset_color '
              $1 !~ /@\.(service|socket|target)$/ && !($1 in units) {
                  unitname = $1
                  otherarg = $2
                  status = $3
                  status_detail = $4
                  description = $NF
                  units[unitname] = 1

                  if (status == "active") {
                    if (status_detail == "running") {
                      indicator = green " " reset
                    } else if (status == "exited") {
                      indicator = green " " reset
                    } else {
                      indicator = green " " reset
                    }
                  } else if (status == "failed") {
                      indicator = red " " reset
                  } else {
                      indicator = " "
                  }

                  print indicator, unitname, $(NF-1)
              }')
}

systest
