#!/bin/bash

CAPTURE_ALL_PANES=1
CAPTURE_ONLY_VISIBLE=0

function capture_active_pane() {
	# Calculating the scroll positions to capture only the visible contents in the panes.
	pane_vals=$(tmux display-message -p -t $1 '#{scroll_region_lower}-#{scroll_position}')
	scroll_height=$(echo $pane_vals | cut -f1 -d-)
	scroll_pos=$(echo $pane_vals | cut -f2 -d-)

}
# :SaveList, ::SaveListAdd, :LoadList, :LoadListAdd,
# :Dofile, :Doline, :Restore, :Keep, :Reject, :ListsLists, :RemoveList
# || "widgets/tmux/butler.filter.sh" 53 lines --26%--


# :SaveList current_loclist
# :cwindow
# :LoadList current_loclist
# <
# Concatenating multiple location lists to use as a quickfix list: >

# :SaveListAdd current_loclist

# < in each location list you want to use, then >

# :cwindow
# :LoadList current_loclist
# <
# Composing a list of files to attach a license to: >

# :grep _GNU_SOURCE
# :Reject false_positives
# :SaveListAdd floss_files
# :grep POSIX_ME_HARDER
# :Reject false_positives
# :SaveListAdd floss_files

# < and so on... >

# <Plug>(qf_qf_previous) ..................... |<Plug>(qf_qf_previous)|
#   <Plug>(qf_qf_next) ......................... |<Plug>(qf_qf_next)|
#   <Plug>(qf_loc_previous) .................... |<Plug>(qf_loc_previous)|
#   <Plug>(qf_loc_next) ........................ |<Plug>(qf_loc_next)|

# Open the quickfix window automatically if there are any errors.
let g:qf_auto_open_quickfix = 0

# Open the location window automatically if there are any locations.
let g:qf_auto_open_loclist = 0

let g:qf_max_height = 8


[Plug>QfCnext] <Plug>(qf_qf_next)

tmuxcmd="tmux capture-pane -p -J -t $1 "
# scoll_pos implies pane in copy mode
if [[ -n $scroll_pos ]]; then
	bottom=$((scroll_height - scroll_pos))
	copyargs="-S -$scroll_pos  -E $bottom"
	tmuxcmd="$tmuxcmd $copyargs"
fi
$tmuxcmd

function capture_pane() {
	tmuxcmd="tmux capture-pane -S - -p -J -t $1"
	$tmuxcmd | tac
}

function capture_pane_visible() {
	# Calculating the scroll positions to capture only the visible contents in the panes.
	pane_vals=$(tmux display-message -p -t $1 '#{scroll_region_lower}-#{scroll_position}')
	scroll_height=$(echo $pane_vals | cut -f1 -d-)
	scroll_pos=$(echo $pane_vals | cut -f2 -d-)
	tmuxcmd="tmux capture-pane -p -J -t $1 "
	# scoll_pos implies pane in copy mode
	if [[ -n $scroll_pos ]]; then
		bottom=$((scroll_height - scroll_pos))
		copyargs="-S -$scroll_pos  -E $bottom"
		tmuxcmd="$tmuxcmd $copyargs"
	fi
	$tmuxcmd
}

function capture_pane() {
	tmuxcmd="tmux capture-pane -S - -p -J -t $1"
	$tmuxcmd | tac
}

# if [ CAPTURE_ALL_PANES -ne 0 ]; then
cur_window=$(tmux display-message -p '#I')
pane_list=$(tmux list-panes -F '#D' -t $cur_window)
for i in $pane_list; do
	capture_pane $window.$i
done
