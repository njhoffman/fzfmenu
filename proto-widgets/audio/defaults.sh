#!/bin/bash

source "$PROJECT_ROOT/essentials.sh"
lazy_declare FMUI_DEFAULTS_SH || return

readonly DIR_TMP="/tmp"
readonly DIR_CONFIG="$HOME/.config/fmui"
readonly DIR_CACHE="$HOME/.cache/fmui"
readonly FILE_CONFIG="$DIR_CONFIG/config"
readonly FILE_KEYBINDINGS="$DIR_CONFIG/keybindings"
readonly BINARY_BASH="$(which bash)"

readonly DEFAULT_SONG_FORMAT='[[[%artist% - ]%title%]|[%file%]]'
readonly DEFAULT_SONG_LIST_FORMAT="%time% [[[%artist% - ]%title%]|[%file%]]"
readonly DEFAULT_PROMPT=$'\xF0\x9D\x84\x9E '
readonly DEFAULT_SEEK_STEP='00:00:10'
# https://github.com/karlstav/cava
# https://github.com/dpayne/cli-visualizer
readonly DEFAULT_VISUALIZER='cava || vis'
readonly DEFAULT_MOD='ctrl'
readonly DEFAULT_FILL_QUEUE=true
readonly DEFAULT_CLEAR_QUEUE=false
readonly DEFAULT_COVER_MAX_WIDTH=500
readonly DEFAULT_COVER_MAX_COLUMNS=30
readonly DEFAULT_MARGIN="0,0,0,0"
readonly DEFAULT_PREVIEW_BOX_SIZE=1
readonly DEFAULT_PREVIEW_BOX_SIZE_COVER=20
readonly DEFAULT_PREVIEW='Mpc::get_options'
readonly DEFAULT_PREVIEW_COVER='Cover::on_selection_changed {1}; Mpc::get_options | xargs -n 2'
