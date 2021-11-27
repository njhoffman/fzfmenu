#!/bin/zsh

CWD="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd -P)"
FZF_LIB="$CWD/../../fzf-lib.zsh"

# FZF_ACTIONS=("kill" "kill:9" "ctrace" "ctrace:verbose" "ltrace" "iotrace" "lsof" )
# FZF_ACTION_DESCRIPTIONS=(
#   "kill process (SIGTERM)"
#   "kill process -9 (SIGKILL)"
#   "ctrace process (only errors)"
#   "ctrace process (all calls)"
#   "ltrace process"
#   "iotrace process"
#   "list all files used by process(es)"
# )
FZF_MODES=('url' 'ip' 'path' 'hash')

export BUTLERTMPDIR="${BUTLERTMPDIR:-/tmp}"
export QUETTYFZF_START="${QUETTYFZF_START:-word}"
DEFAULTPASTER="${DEFAULTPASTER:-$CWD/paste-to-tmux}"
DEFAULTVIEWER="${DEFAULTVIEWER:-$CWD/tmux-split}"
DEFAULTREADER="${DEFAULTREADER:-$CWD/capture_panes}"
DEFAULTSELECTOR="${DEFAULTSELECTOR:-$CWD/quetty-fzf}"
DEFAULTFILTER="${DEFAULTFILTER:-cat}"
FZFHEADER="${FZFHEADER:-} "
FZFBINDING="${FZFBINDING:-alt-e:execute(touch $BUTLERTMPDIR/editorf)+accept}"

PASTER="${PASTER:-$DEFAULTPASTER}"
VIEWER="${VIEWER:-$DEFAULTVIEWER}"
# Override example: cd $(dirname `which tmux-butler`); READER="scripts/capture_panes | scripts/quetty -ip" tmux-butler
READER="${READER:-$DEFAULTREADER}"
FILTER="${FILTER:-$DEFAULTFILTER}"
SELECTOR="${SELECTOR:-$DEFAULTSELECTOR}"

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
_clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
}


_fzf-extra-opts() {
  opts=""
  # opts="${opts} --header-lines=1"
  echo "$opts"
}

_fzf-result() {
  action="$1" && shift
  items=($@)
  _fzf-log "${CWD} result $action (${#items[@]}): \n${items[@]}"

  for item in "$items[@]"; do
    echo "butler $item"
  done
}

_fzf-preview() {
  echo "These are my preview pids: $1"
}


_fzf-source() {
	cur_window=$(tmux display-message -p '#I')
	pane_list=$(tmux list-panes -F '#D' -t $cur_window)
	for i in $pane_list; do
		capture_pane $window.$i
	done
}

source "$CWD/butler.lib.sh"

startmode="url"

while (( "$#" ));do
	case $1 in
		-h|--help)
			printhelp
			exit 0
			;;
		-start)
			if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
				startmode=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		*)
			echo "Invalid Option: $1" 1>&2
			printhelp
			exit 1
			;;
	esac
done

export QUETTYFZF_START="$startmode"

#### start execution
outputf="$BUTLERTMPDIR/tmux-butler-outputfile"
stage1f="$BUTLERTMPDIR/tmux-butler-stage1"
stage2fifo="$BUTLERTMPDIR/tmux-butler-stage2-fifo"
stage2f="$BUTLERTMPDIR/tmux-butler-stage2"
selectorcmdf="$BUTLERTMPDIR/tmux-butler-selectorcmdf"
readercmdf="$BUTLERTMPDIR/tmux-butler-readercmdf"
processorcmdf="$BUTLERTMPDIR/tmux-butler-processorcmdf"
pastercmdf="$BUTLERTMPDIR/tmux-butler-pastercmdf"
editorcmdf="$BUTLERTMPDIR/editorf"
editorfifo="$BUTLERTMPDIR/editorfifo"
editorinput="$BUTLERTMPDIR/editorinput"
rm -f $editorcmdf

cleanup() {
	rm -f $outputf $stage1f $stage2fifo $stage2f $selectorcmdf  $readercmdf $processorcmdf $pastercmdf $editorcmdf
}
[[ -z $BUTLERDEBUG ]] && trap 'cleanup' EXIT

### STAGE 1 - Fetch initial contents
cat <<< "$READER > $stage1f" > $readercmdf
sh $readercmdf
if [[ ! -s "$stage1f" ]]; then
	# Empty file. Exit
	exit 0
fi

### STAGE 2 - Let the user pick a selection from the fetched input using a selector ( usually fzf )
rm -f $stage2fifo
# Need a fifo because terminalcmds won't wait for the selector cmd to finish
mkfifo $stage2fifo

cat <<< "cat $stage1f | $SELECTOR  > $stage2fifo" > $selectorcmdf
$VIEWER $selectorcmdf
cat < $stage2fifo > $stage2f

# Empty file. Exit
[[ ! -s "$stage2f" ]] &&  exit 0

### STAGE3 - Any final processing of the output selected required. Can be passthrough using cat
cat <<< "cat $stage2f | $FILTER | perl -pe 'chomp if eof' > $outputf" > $processorcmdf
sh $processorcmdf
if [[ $? -eq 1 ]] || [[ ! -s "$outputf" ]]; then
	rm $outputf
	exit 0
fi

if [[ -f "$editorcmdf" ]]; then
	cp $outputf $editorinput
	rm -f $editorfifo
	mkfifo $editorfifo
	cat <<< "vim $editorinput; cat $editorinput > $editorfifo" > $editorcmdf
	$VIEWER $editorcmdf
	cat < $editorfifo | perl -pe 'chomp if eof' > $outputf
fi

cat $outputf >> $CWD/.history
echo >> $CWD/.history

### STAGE 4 - paste the output into tmux/clipboard
cat <<< "cat $outputf | $PASTER" > $pastercmdf
sh $pastercmdf
exit 0

_fzf-source

# source "$FZF_LIB"
