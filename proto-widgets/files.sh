#!/bin/env bash

export data="${XDG_DATA_HOME:-$HOME/.local/share}/iii"
command mkdir -p "$data"

show-help() {
  pager <(
    printf '
+----------------------------------------------+
|          iii:  fzf file manager              |
+----------------------------------------------+

iii is an example of how to build a simple file manager out of fzf. If you want to actually use it, fork the code and play around with it, change everything, explore the composability of fzf and TUI world.

iii implements the following features.

- find over current directory or finding over all files (Ctrl-/ to toggle).
- open files and dirs (Ctrl-l, Alt-l, Ctrl-o, Ctrl-g).
- toggle hidden files (Alt-h).
- select multiple files (Tab and then Alt-c to save remember selections, remove saved selections with Alt-x).
- cp saved selections to PWD (Alt-y).
- mv saved selections to PWD (Alt-v).
- create files/dirs (Alt-Enter).
- rename files (Alt-r).
- open special directories (~ for HOME, Ctrl-^ for OLDPWD).
- or mark directories (`, |), fuzzy find over them (\).
- and we can preview files and directories, of course.

Note that fzf has the following limitation: you cant preselect entries in list, because it is asynchronous or something like that. So we need to save selections before we reload our list (when we change directories, etc). We cant do some selection, change directory and select something else, like in ranger or lf, and then do an operation for this file; we need to select files without reloading list. Maybe we could append new selected files instead of overwriting them, but since we cant preselect them, it could be confusing: we cant see if a file in a list is already selected...
So maybe for file operations it is better to use a dedicated file managers like lf and just integrate fzf into it.


List of keybindings.

?: help
<C-r>: reload
<C-c>: exit

<C-j>, <C-k>: down, up
<C-h>: updir
<C-l>, <Enter>: open dir or edit file
<C-g>: cd parent file under cursor
<A-l>: open pager for file
<C-o>: open file in external app

C-/: toggle deep finder
<A-h>: toggle hidden

~: cd ~
<C-^>: cd -
\\: marks
\`: mark pwd
|: edit file with marks

<A-j>, <A-k>: scroll preview

<Tab>, <S-Tab>: select
<Escape>: clear selections
<A-a>: toggle select all
<A-c>: save current selections for operations below
<A-y>: cp saved selections to pwd
<A-v>: mv saved selections to pwd
<A-x>: rm saved selections
<A-r>: rename file
    <A-Enter>: create new file or directory (if has trailing /)'
  )
}
export -f show-help
# We 'export -f' all the functions that should be visible for fzf process.

# Populate fzf with file list.
files() {
  c="fd -L --color=always --full-path ."
  [[ ! -f "$data/deep" ]] && c=" $c --max-depth 1" || c=" $c --max-depth 3"
  [[ -f "$data/hidden" ]] && c=" $c -H"
  $c
}
export -f files

# To save options, we create and remove files.
# We can't modify parent shell variables in a subshell (in fzf).
toggle-opt() {
  if [[ -f "$data/$1" ]]; then
    command rm -f "$data/$1" > /dev/null 2>&1
  else
    touch "$data/$1"
  fi
}
export -f toggle-opt

# set-opt() {
#     touch "$data/$1"
#     echo "$2" > "$data/$1"
# }

# get-opt() {
#     cat "$data/$1"
# }

# Get list of bookmarks.
marks() {
  touch "$data/marks"
  while read -r f; do
    realpath "$f"
  done < "$data/marks"
}
export -f marks

# External file opener.
open() {
  xdg-open "$@"
}
export -f open

# Previewer, just an example.
preview() {
  case "$(file --dereference --brief --mime-type -- "$1")" in
    inode/directory) tree -C -L 3 "$1" ;;
    image/*) chafa "$1" ;; # chafa transforms images to text!
    *) batcat --style=plain --color=always "$1" ;;
  esac
}
export -f preview

pager() {
  # this /dev/tty thing is important: `less` should read user input from stdin.
  less -R -f "$@" < /dev/tty > /dev/tty 2>&1
}
export -f pager

# Save which files we selected for further manipulation.
save() {
  echo -n > "$data/selections"
  while read -r f; do
    realpath "$f" >> "$data/selections"
  done < "$1" # $1 is {+f}, i.e. temporary file with selection created by fzf.
}
export -f save

# Copy selection to current PWD.
copy() {
  # im lazy to fix this. we have both user input and file in stdin, so this simple loop doesnt work.
  # while read -r f <&3; do
  #     cp -rvi "$f" "$PWD" >/dev/null 2>&1;
  # done < "$data/selections";
  for f in $(cat "$data/selections"); do
    cp -rvi "$f" "$PWD" > /dev/null 2>&1
  done
  echo -n > "$data/selections"
}
export -f copy

# Move selection to current PWD.
move() {
  # while read -r f <&3; do
  #     mv -i "$f" "$PWD" >/dev/null 2>&1;
  # done < "$data/selections";
  for f in $(cat "$data/selections"); do
    mv -i "$f" "$PWD" > /dev/null 2>&1
  done
  echo -n > "$data/selections"
}
export -f move

# Delete selections.
remove() {
  # while read -r f; do
  #     rm -rvI -- "$f"
  # done < "$data/selections";
  for f in $(cat "$data/selections"); do
    rm -rvI -- "$f"
  done
  echo -n > "$data/selections"
}
export -f remove

# Rename current file.
rename() {
  read -r -p "rename: $1 -> " n
  mv -v "$1" "$n"
}
export -f rename

# Create 'file' or 'new/directory/'
create() {
  read -r -p 'create file or directory: ' f
  [[ ! $f ]] && return
  if [[ $f == */ ]]; then
    mkdir -pv "$f" && cd "$f" || return 1
  else
    touch "$f"
    $EDITOR "$f"
  fi
}
export -f create

# Append current PWD to bookmarks.
mark-add() {
  echo "$1" >> "$data/marks"
}
export -f mark-add

# Open bookmark file.
mark-edit() {
  $EDITOR "$data/marks"
}
export -f mark-edit

reload="reload[files]"

iii() {
  while :; do
    s="$(
      fzf \
        --no-clear \
        --multi \
        --ansi \
        --preview="preview {}" \
        --preview-window=right,66%,border-left \
        --border=bold \
        --prompt="$(basename -- "$PWD") \$ " \
        --margin=2% \
        --scroll-off=5 \
        --info=inline \
        --no-scrollbar \
        --header='Press ? for help!' \
        --bind="start:$reload" \
        --bind="?:execute[show-help]" \
        --bind="ctrl-c:abort" \
        --bind="tab:toggle+down" \
        --bind="shift-tab:toggle+up" \
        --bind="esc:clear-selection" \
        --bind="alt-a:toggle-all" \
        --bind="alt-j:preview-down" \
        --bind="alt-k:preview-up" \
        --bind="alt-h:execute[toggle-opt hidden]+$reload" \
        --bind="ctrl-/:execute[toggle-opt deep]+$reload" \
        --bind="ctrl-k:up" \
        --bind="ctrl-j:down" \
        --bind="ctrl-h:become[echo ..]" \
        --bind="ctrl-l:become[echo {}]" \
        --bind="ctrl-g:become[dirname {}]" \
        --bind="alt-l:execute[pager {}]" \
        --bind="ctrl-o:execute-silent[open {+}]" \
        --bind="alt-c:execute-silent[save {+f}]+clear-selection" \
        --bind="alt-v:execute[move]+$reload" \
        --bind="alt-y:execute[copy]+$reload" \
        --bind="alt-x:execute[remove]+$reload" \
        --bind="alt-r:execute[rename {}]+$reload" \
        --bind="alt-enter:execute[create]+$reload" \
        --bind="ctrl-^:become[echo $OLDPWD]+$reload" \
        --bind="~:become[echo $HOME]" \
        --bind="ctrl-r:$reload" \
        --bind="\\:reload[marks]" \
        --bind="|:execute[mark-edit]" \
        --bind="\`:execute-silent[mark-add $PWD]"
    )"
    [[ ! $s ]] && break

    d="$(echo "$s" | tail -n1)"

    # maybe we can store PWD externally and cd without constantly reopening fzf in loop...
    # you are free to experiment with implementing it
    if [[ -d $d ]]; then
      cd "$d" || continue
    elif [[ -f $d ]]; then
      $EDITOR "$d"
    else
      break
    fi
  done
  clear # we used --no-clear in fzf so it doesnt fliker after restart
}
iii
