#!/bin/zsh

CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"

FZF_LOGFILE=${FZF_LOGFILE:-"/tmp/fzf.log"}

setopt localoptions noglobsubst noposixbuiltins pipefail 2>> ${FZF_LOGFILE:-/dev/null}

source "${FZF_LIB}.log.sh"
source "${FZF_LIB}.sh"

_fzf-verify() {
  # ensure functions exist: _fzf-source, _fzf-result
}

declare -A _clr
declare -A _fzf_keys

# assigns default colors keys that can be overridden by each module
_fzf-assign-vars-default() {
  local lc=$'\e[' rc=m
  _clr[rst]="${lc}0${rc}"
  # _clr[mode_active]="${lc}${CLR_MODE_ACTIVE:-38;5;117}${rc}"
  # _clr[mode_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;68}${rc}"
  _clr[mode_active]="${lc}${CLR_MODE_ACTIVE:-38;5;45;1}${rc}"
  _clr[mode_inactive]="${lc}${CLR_MODE_INACTIVE:-38;5;240}${rc}"
  _clr[toggle_active]="${lc}${CLR_TOGGLE_ACTIVE:-38;5;49}${rc}"
  _clr[toggle_inactive]="${lc}${CLR_TOGGLE_INACTIVE:-38;5;240}${rc}"
  _clr[divider]="${lc}${CLR_DIVIDER:-38;5;59}${rc}"
  _clr[action_id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[action_desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
  # TODO: implement this into preview window as well
  # _clr[action_header]=""
  # _clr[action_target]=""
  _clr[rst]="${lc}0${rc}"

  _fzf_keys[toggle_popout]="ctrl-^"
  _fzf_keys[reload]="ctrl-r"
  _fzf_keys[mode_prev]="alt-9"
  _fzf_keys[mode_next]="alt-0"
  _fzf_keys[nop]="ctrl-]"
  _fzf_keys[actions_menu]='ctrl-\'
  _fzf_keys[help_menu]=""
  _fzf_keys[exit]="esc"


  [[ "$(command -V _fzf-assign-vars)" =~ "function" ]] && \
    _fzf-assign-vars

  # assign tmux padding based on width
  if [[ -n "$TMUX" ]]; then
    tmux_width=$(tmux display-message -p "#{window_width}")
    tmux_padding="-p40%"
    [[ tmux_width -lt 400 ]] && tmux_padding="-p50%"
    [[ tmux_width -lt 200 ]] && tmux_padding="-p60%"
    export FZF_TMUX_OPTS="${FZF_TMUX_OPTS:-${tmux_padding}}"
    _fzf-log "TMUX OPTS 1: $FZF_TMUX_OPTS"

  fi
}

# FZF_ACTIONS: output the "action menu" if defined by if _fzf_kekys[action_menu] pressed
_fzf-actions-source-default() {
  lines=()
  for ((i=1; i<=${#FZF_ACTIONS}; i++)); do
    id="$FZF_ACTIONS[$i]"
    desc="$FZF_ACTION_DESCRIPTIONS[$i]"
    lineout="${_clr[rst]}${_clr[action_id]}${id}"
    lineout="${lineout}|${_clr[action_desc]}${desc}"
    lineout="${lineout}|${cmd}${_clr[rst]}"
    lines+=( "$lineout" )
  done
  printf '%s\n' "${lines[@]}" | column -t -s'|'
}

# action menu handlers (can be added or overridden by modules)
_fzf-result-default() {
  # _fzf-log "handle result lines: $* \n--"
  action="$1" && shift
  items=($@)
  item_ids=($(printf "%s\n" ${items[@]} | cut -d' ' -f1))

  # custom actions, to override default actions below must exit 0
  [[ "$(command -V _fzf-result)" =~ "function" ]] \
    && _fzf-result $action $items

  if [[ "$action" == "echo:id" ]]; then
    printf "%s\n" ${item_ids[@]}
  elif [[ "$action" == "echo:preview" ]]; then
    echo "Preview ${#items[@]} item names"
  elif [[ "$action" == "yank:id" ]]; then
    printf "%s\n" ${items_ids[@]} | xsel --clipboard
    echo "Copied ${#items[@]} item names to clipboard"
  elif [[ "$action" == "yank:preview" ]]; then
    echo "${#items[@]} to preview" | xsel --clipboard
    echo "Copied ${#items[@]} preview items to clipboard "
  fi
}

# main display loop for fzf until exit key is pressed or action is finished
_fzf-display() {
  local query="$*"
  local selected=()
  local action_menu=()

  local fzf_cmd="fzf"
  local fzf_cmd_args=""

  # use fzf-tmux if inside TMUX and FZF_TMUX is set
  if [ -n "$TMUX_PANE" ] && [ "${FZF_TMUX:-0}" != 0 ]; then
    fzf_cmd="fzf-tmux"
    fzf_cmd_args="${FZF_TMUX_OPTS}"
  fi

  # TODO: add get_mode_id function
  local mode=${FZF_DEFAULT_MODE:-1}
  local toggle_vals=${FZF_TOGGLES_DEFAULT:-}

  ORIG_FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS

  local key=$_fzf_keys[reload]
  # TODO: turn mode into FZF_MODE, try to break this up
  while [[ -n "$key" && "$key" != ${_fzf_keys[exit]} ]]
    do
      query=""
      _fzf_log_first=0

      # if popout key pressed, toggle between fzf and fzf-tmux
      if [[ $key == $_fzf_keys[toggle_popout] ]]; then
        if [[ $fzf_cmd == "fzf-tmux" ]]; then
          fzf_cmd="fzf"
          fzf_cmd_args=""
        else
          fzf_cmd="fzf-tmux"
          fzf_cmd_args="${FZF_TMUX_OPTS:--p80%}"
        fi
      fi

      local header=""
      local fzf_opts=""
      # show actions submenu
      if [ ${#action_menu[@]} -gt 0 ]; then
        # fzf_opts="--header-first"
        fzf_opts="--no-multi --print-query --preview-window=:hidden"
        if [ ${#action_menu[@]} -gt 1 ]; then
          header="Perform action on ${#action_menu[@]} items"
        else
          header="Perform action on: $(cut -d' ' -f1 <<<${action_menu[1]})"
        fi

        [[ -n "$header" ]] && fzf_opts="${fzf_opts} --header='${header}'"

        [[ "$(command -V _fzf-prompt)" =~ "function" ]] && \
          fzf_opts="${fzf_opts} --prompt='$(_fzf-prompt $mode)'"

        expected_keys="enter,${_fzf_keys[exit]},${_fzf_keys[reload]},${_fzf_keys[toggle_popout]}"
        expected_keys="${expected_keys},${_fzf_keys[actions_menu]}"
        fzf_opts="${fzf_opts} --expect='$expected_keys'"

        FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

        # only output the text without piping to fzf
        if [[ $FZF_RAW_OUT -eq 1 ]]; then
          IFS=$'\n' result=($(_fzf-actions-source-default $mode))
          printf "%s\n" "${result[@]}" | column -t
          exit 0
        fi

        if [[ "$fzf_cmd" == "fzf-tmux" ]]; then
          fzf_cmd_args="-w50% -h30%"
        fi

        # actually perform fzf command here
        IFS=$'\n' result=($(_fzf-actions-source-default $mode | $fzf_cmd $fzf_cmd_args ))

        # determine if query was submitted by identifying line exit key is on
        if [[ ${#result[@]} -gt 2 && $expected_keys =~ ${result[2]} ]]; then
          query="$(echo ${result[1]} | xargs)"
          key="$(echo ${result[2]} | xargs)"
          selected_action="$(cut -d' ' -f1 <<<${result[@]:2})"
        else
          query=""
          key="$(echo ${result[1]} | xargs)"
          selected_action="$(cut -d' ' -f1 <<<${result[@]:1})"
        fi

        local log_lines=()
        local lines=$(_fzf-actions-source-default $mode | head -n 5)
        [[ -n "$query" ]] && log_lines+=("query:\t${query}")
        [[ -n "$key" ]] && log_lines+=("exit-key:\t${key}")
        [[ -n "$selected_action" ]] && log_lines+=("select-action:\t${selected_action}")
        _fzf-log "actions menu top 5: \n${lines[@]}\n-\n${log_lines[@]}"

        # perform action (selected) on item(s) (action_menu) if enter or back to previous menu
        if [[ "$key" == "enter" ]]; then
          _fzf-log "_fzf-result - $selected_action (${#action_menu[@]} items)"
          _fzf-result-default "$selected_action" "${action_menu[@]}"
          key="${_fzf_keys[exit]}"
        else
          action_menu=""
          key="${_fzf_keys[reload]}"
        fi

      # show main list menu
      else

        if [[ ${#FZF_TOGGLES[@]} -gt 0 ]]; then
          if [[ $key =~ "alt-." ]]; then
            toggle_idx=${key[$(($MBEGIN+4)),$MEND]}
            toggle_val=$(echo "$toggle_vals" | cut -f${toggle_idx} -d' ')
            if [[ $toggle_val -eq 0 ]]; then
              toggle_val=1
            else
              toggle_val=0
            fi
            _fzf-log "toggle $toggle_idx $toggle_val: $toggle_vals"
            toggle_vals=$(echo "$toggle_vals" \
              | sed "s/[0-9]\+/$toggle_val/$toggle_idx")
          fi
        fi

        # if modes defined and key pressed was a function key or a mode-left / mode-right key
        if [[ ${#FZF_MODES[@]} -gt 0 ]]; then
          if [[ $key =~ "f." ]]; then
            mode=${key[$(($MBEGIN+1)),$MEND]}
          elif [[ "$key" == $_fzf_keys[mode_prev] ]]; then
            if [[ $mode -eq 1 ]]; then
              mode=$(($#FZF_MODES))
            else
              mode=$((($mode-1 % $#FZF_MODES)))
            fi
          elif [[ "$key" == $_fzf_keys[mode_next] \
            || "$key" == $_fzf_keys[nop] ]]; then
            mode=$((($mode % $#FZF_MODES) + 1))
          fi

          # optional function to customize widget props based on mode
          [[ "$(command -V _fzf-assign-mode)" =~ "function" ]] \
            && _fzf-assign-mode $mode
        fi

        # render header lines
        if [[ "$(command -V _fzf-header)" =~ "function" ]]; then
           header="$(_fzf-header $mode)"
        else
          hints=$(_fzf-mode-hints $mode)
          toggle_hints=$(_fzf-toggle-hints $toggle_vals)
          if [[ -n "$toggle_hints" && -n "$hints" ]]; then
            hints="$hints|  $toggle_hints"
          elif [[ -n "$toggle_hints" ]]; then
            hints="$toggle_hints"
          fi
          [[ -n "$hints" ]] && _fzf-log "hints:\t${hints}"
          header="${hints:-}"
        fi

        # TODO: any other way to embed hard line break?
        [[ $FZF_DIVIDER_SHOW -eq 1 ]] && header="${header}
${_clr[divider]}${FZF_DIVIDER_LINE}${_clr[rst]}"

        [[ -n "$header" ]] && fzf_opts="${fzf_opts} --header='${header}'"

        # optional functions: customize preview, prompt, options, header
        [[ "$(command -V _fzf-preview)" =~ "function" ]] && \
          fzf_opts="${fzf_opts} --preview='${SOURCE} --preview $mode {1}'"

        [[ "$(command -V _fzf-prompt)" =~ "function" ]] && \
          fzf_opts="${fzf_opts} --prompt='$(_fzf-prompt $mode)'"

        [[ "$(command -V _fzf-extra-opts)" =~ "function" ]] && \
          fzf_opts="${fzf_opts} $(_fzf-extra-opts $mode)"

        fzf_opts="${fzf_opts} --ansi --print-query"
        fzf_opts="${fzf_opts} --preview-window='right:50%:wrap'"
        fzf_opts="${fzf_opts} --tiebreak=index --no-hscroll --query='${query}'"

        # keys that can exit
        # expected_keys="enter,esc,ctrl-r,ctrl-^,alt-9,alt-0,ctrl-space"
        expected_keys="enter,${_fzf_keys[exit]},${_fzf_keys[reload]},${_fzf_keys[toggle_popout]}"
        expected_keys="${expected_keys},${_fzf_keys[mode_prev]},${_fzf_keys[mode_next]},${_fzf_keys[nop]}"
        expected_keys="${expected_keys},${_fzf_keys[actions_menu]}"

        # TODO: only for count of fzf_modes
        [[ -n "{$FZF_MODES[@]}" ]] && expected_keys="${expected_keys},f1,f2,f3,f4,f5"
        fzf_opts="${fzf_opts} --expect='$expected_keys'"

        [[ -n "${FZF_TOGGLES[@]}" ]] && expected_keys="${expected_keys},alt-1,alt-2,alt-3,alt-4,alt-5"
        fzf_opts="${fzf_opts} --expect='$expected_keys'"

        if [ $FZF_CLEAR -eq 1 ]; then
          fzf_opts="${fzf_opts} --clear"
        else
          fzf_opts="${fzf_opts} --no-clear"
        fi

        FZF_DEFAULT_OPTS="${ORIG_FZF_DEFAULT_OPTS} ${fzf_opts}"

        [[ "$(command -V _fzf-action)" =~ "function" ]] && \
          FZF_DEFAULT_ACTION="$(_fzf-action $mode)"

        if [[ "$(command -V _fzf-source)" =~ "function" ]]; then
          # only output the text without piping to fzf
          if [[ $FZF_RAW_OUT -eq 1 ]]; then
            IFS=$'\n' result=($(_fzf-source $mode))
            printf "%s\n" "${result[@]}" | column -t && key="" && exit 0
          fi
          IFS=$'\n' result=($(_fzf-source $mode | $fzf_cmd $fzf_cmd_args | sed 's/^ *//' ))
        elif [[ "$(command -V _fzf-command)" =~ "function" ]]; then
          FZF_DEFAULT_COMMAND="$(_fzf-command $mode)"
          # only output the text without piping to fzf
          if [[ $FZF_RAW_OUT -eq 1 ]]; then
            IFS=$'\n' result=($(eval "$FZF_DEFAULT_COMMAND $mode"))
            printf "%s\n" "${result[@]}" | column -t && key="" && exit 0
          fi
          IFS=$'\n' result=($($fzf_cmd $fzf_cmd_args | sed 's/^ *//' ))
        fi

        # determine if query was submitted by identifying line exit key is on
        if [[ ${#result[@]} -gt 2 && $expected_keys == *${result[2]}* ]]; then
          query="$(echo ${result[1]} | xargs)"
          key="$(echo ${result[2]})" # xargs on key removes "ctrl-\"
          selected=(${result[@]:2})
        else
          query=""
          key="$(echo ${result[1]})"
          selected=(${result[@]:1})
        fi

        _fzf-log "main results: \n${result[@]}\n"

        # TODO: find a way around buffering
        local lines=$(eval "$FZF_DEFAULT_COMMAND" | head -n 5)
        local log_lines=()
        [[ -n "$query" ]] && log_lines+=("query:\t${query}")
        [[ -n "$key" ]] && log_lines+=("exit-key:\t${key}")
        [[ -n "$selected[@]" ]] && log_lines+=("selected:\t${#selected[@]} items")
        for item in "${selected[@]}"; do log_lines+=("  ${item}") done

        # log_lines+=("\noptions: $fzf_opts")
        _fzf-log "main menu top 5: $has_query\n${lines[@]}\n--\n${log_lines[@]}"

        if [[ "$key" == "${_fzf_keys[actions_menu]}" ]]; then
          action_menu=("${selected[@]}")
        else
          action_menu=()
        fi

        if [[ "$key" == "enter" ]]; then
          if [[ -n "$FZF_DEFAULT_ACTION" ]]; then
            _fzf-result-default "$FZF_DEFAULT_ACTION" "$selected"
          else
            action_menu=("${selected[@]}")
          fi
        fi
      fi
    done
}


# main arguments handler to parse argument settings and invoke different outputs
_fzf-main() {

  # ensure correct functions are declared depending on options and assignments
  _fzf-verify

  # assign default keys and colors with optional override
  _fzf-assign-vars-default

  # flag to pipe output (list or preview) to stdout instead of fzf
  [[ "$1" == "--raw" ]] && \
    shift && FZF_RAW_OUT=1

  # generate preview content
  if [[ "$1" == "--preview" ]]; then
    shift && [[ "$(command -V _fzf-preview)" =~ "function" ]] \
      && eval "_fzf-preview $*"
  # output dynamic menu description
  elif [[ $1 == "--description" ]]; then
    shift && [[ "$(command -V _fzf-menu-description)" =~ "function" ]] && \
			eval "_fzf-menu-description $*"
  # list module actions and settings
  elif [[ $1 == "--list" || $1 == "-l" ]]; then
    shift && echo "LIST"
  # show usage information on the command line
  elif [[ $1 == "--help" || $1 == "-h" ]]; then
    shift && echo "HELP"
  # launch main fzf display loop, remaining arguments should be lookup query
  else
    # clear && echo -e "\nLoading $SOURCE..."
    [[ "$1" == "--action" || "$1" == "-a" ]] && \
      shift && FZF_DEFAULT_ACTION="$1" && shift
    [[ "$1" == "--popup" || "$1" == "-p" ]] && \
      shift && FZF_TMUX="1"
    _fzf-display $@
  fi

}

_fzf-main $@
