#!/bin/zsh

sudo "" 2>/dev/null

autoload -U colors
colors

# list-unit-files: 467
# list-units: 278 loaded
# list-units -all: 515 listed
systest() {
   # --ansi --tiebreak=index ${(Q)${(Z+n+)fzf_options}} ${(Q)${(Z+n+)${_fzf_complete_preview_systemctl_status/\$SYSTEMCTL_OPTIONS/$systemctl_options}}} ${(Q)${(Z+n+)FZF_DEFAULT_OPTS}} -- "$@" < \
   # active (running) active(waiting) active(plugged) active(listening) active (exited)
   # inactive (dead)
   # service|socket|target|mount|device
   #          ⭘ ⏼  ○ ●

   MANAGERS=(user system)

   local lc=$'\e[' rc=m
   prefix=""
   clr_green1="${lc}${CLR_ID:-38;5;30}${rc}"
   for MANAGER in "${MANAGERS[@]}"; do
     local systemctl_options=(--full --no-legend --no-pager --plain)
     systemctl_options+=("--$MANAGER")
     cat < \
        <({
            systemctl list-units ${(Q)${(Z+n+)systemctl_options}} "$prefix*"
            systemctl list-unit-files ${(Q)${(Z+n+)systemctl_options}} "$prefix*"
        } | LC_ALL=C sort -b -f -k 1,1 -k 3,3r \
          | awk \
                -v green=${fg[green]} \
                -v manager=${MANAGER} \
                -v red=${fg[red]} \
                -v reset=$reset_color '
                $1 !~ /@\.(service|socket|target)$/ && !($1 in units) {
                    unitname = $1
                    otherarg = $2
                    status = $3
                    status_detail = $4
                    description = $NF
                    units[unitname] = 1
                    if (unitname != "" && status != "") {
                      if (status == "active" ) {
                        if (status_detail == "running") {
                          indicator = green "" reset
                        } else if (status == "exited") {
                          indicator = green "" reset
                        } else {
                          indicator = green "" reset
                        }
                      } else if (status == "failed") {
                          indicator = red "" reset
                      } else {
                          indicator = ""
                      }
                      print " "indicator" ["manager"] ", unitname
                  }
                }')
              done
}

systest


# ├──────────────────┼──────────────────────────┼───────────┤
# │"enabled"         │ Enabled via .wants/,     │           │
# ├──────────────────┤ .requires/ or Alias=     │           │
# │"enabled-runtime" │ symlinks (permanently in │ 0         │
# │                  │ /etc/systemd/system/, or │           │
# │                  │ transiently in           │           │
# │                  │ /run/systemd/system/).   │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"linked"          │ Made available through   │           │
# ├──────────────────┤ one or more symlinks to  │           │
# │"linked-runtime"  │ the unit file            │           │
# │                  │ (permanently in          │           │
# │                  │ /etc/systemd/system/ or  │           │
# │                  │ transiently in           │ > 0       │
# │                  │ /run/systemd/system/),   │           │
# │                  │ even though the unit     │           │
# │                  │ file might reside        │           │
# │                  │ outside of the unit file │           │
# │                  │ search path.             │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"alias"           │ The name is an alias     │ 0         │
# │                  │ (symlink to another unit │           │
# │                  │ file).                   │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"masked"          │ Completely disabled, so  │           │
# ├──────────────────┤ that any start operation │           │
# │"masked-runtime"  │ on it fails (permanently │ > 0       │
# │                  │ in /etc/systemd/system/  │           │
# │                  │ or transiently in        │           │
# │                  │ /run/systemd/systemd/).  │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"static"          │ The unit file is not     │ 0         │
# │                  │ enabled, and has no      │           │
# │                  │ provisions for enabling  │           │
# │                  │ in the [Install] unit    │           │
# │                  │ file section.            │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"indirect"        │ The unit file itself is  │ 0         │
# │                  │ not enabled, but it has  │           │
# │                  │ a non-empty Also=        │           │
# │                  │ setting in the [Install] │           │
# │                  │ unit file section,       │           │
# │                  │ listing other unit files │           │
# │                  │ that might be enabled,   │           │
# │                  │ or it has an alias under │           │
# │                  │ a different name through │           │
# │                  │ a symlink that is not    │           │
# │                  │ specified in Also=. For  │           │
# │                  │ template unit files, an  │           │
# │                  │ instance different than  │           │
# │                  │ the one specified in     │           │
# │                  │ DefaultInstance= is      │           │
# │                  │ enabled.                 │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"disabled"        │ The unit file is not     │ > 0       │
# │                  │ enabled, but contains an │           │
# │                  │ [Install] section with   │           │
# │                  │ installation             │           │
# │                  │ instructions.            │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"generated"       │ The unit file was        │ 0         │
# │                  │ generated dynamically    │           │
# │                  │ via a generator tool.    │           │
# │                  │ See                      │           │
# │                  │ systemd.generator(7).    │           │
# │                  │ Generated unit files may │           │
# │                  │ not be enabled, they are │           │
# │                  │ enabled implicitly by    │           │
# │                  │ their generator.         │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"transient"       │ The unit file has been   │ 0         │
# │                  │ created dynamically with │           │
# │                  │ the runtime API.         │           │
# │                  │ Transient units may not  │           │
# │                  │ be enabled.              │           │
# ├──────────────────┼──────────────────────────┼───────────┤
# │"bad"             │ The unit file is invalid │ > 0       │
# │                  │ or another error         │           │
# │                  │ occurred. Note that      │           │
# │                  │ is-enabled will not      │           │
# │                  │ actually return this     │           │
# │                  │ state, but print an      │           │
# │                  │ error message instead.   │           │
# │                  │ However the unit file    │           │
# │                  │ listing printed by       │           │
# │                  │ list-unit-files might    │           │
# │                  │ show it.                 │           │
# └──────────────────┴──────────────────────────┴───────────┘
