#!/usr/bin/env bash

ROOTDIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"

function tokenize_content() {
	source
	REGEXLIST=()
	FILTERLIST=()
	minchars=4

	# add each -r arg to REGEXLIST
	while (("$#")); do
		case "$1" in
		-regex)
			if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
				REGEXLIST+=($2)
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		-min)
			if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
				minchars=$2
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		-hash)
			REGEXLIST+=($HASHREGEX)
			shift
			;;
		-word)
			REGEXLIST+=($WORDREGEX)
			REGEXLIST+=($IDENTREGEX)
			REGEXLIST+=($IDENTREGEXWITHDOT)
			shift
			;;
		-url)
			REGEXLIST+=($URLREGEX)
			# REGEXLIST+=($GITURLREGEX)
			shift
			;;
		-num)
			REGEXLIST+=($NUMREGEX)
			shift
			;;
		-nospace)
			REGEXLIST+=($NOSPACEREGEX)
			shift
			;;
		-ip)
			REGEXLIST+=($IPCOMBINED)
			REGEXLIST+=($PREFIXCOMBINED)
			shift
			;;
		-h | --help)
			printhelp
			exit 0
			;;
		-*)
			filter=${1#"-"}
			filter_file=$ROOTDIR/filters/"$filter"
			if [[ ! -x $filter_file ]]; then
				echo "Error: No filter $filter_file"
				exit 1
			fi
			FILTERLIST+=($filter_file)
			shift
			;;
		*)
			echo "Invalid Option: $1" 1>&2
			printhelp
			exit 1
			;;
		esac
	done

	inpfile="${BUTLERTMPDIR:-/tmp}/quetty-input-file"
	tmpfile="${BUTLERTMPDIR:-/tmp}/quetty-tmp-file"
	cleanup() {
		rm -f $inpfile $tmpfile
	}
	[[ -z $BUTLERDEBUG ]] && trap 'cleanup' EXIT

	rm -f $tmpfile
	touch $tmpfile
	cat >$inpfile

	# Read input to tmp file for reuse
	for reg in "${REGEXLIST[@]}"; do
		cat $inpfile | egrep -o $reg >>$tmpfile
	done

	for tkner in "${FILTERLIST[@]}"; do
		cat $inpfile | $tkner >>$tmpfile
	done

	#             i      

	# Sort and uniq the output
	cat $tmpfile | egrep -o ".{$minchars,}" |
		sort |
		uniq |
		shuf

}
