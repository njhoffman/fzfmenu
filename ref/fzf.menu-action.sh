#!/bin/bash

declare -A clr
lc=$'\e[' rc=m
clr[action_id]="${lc}${CLR_ID:-38;5;30}${rc}"
clr[action_desc]="${lc}${CLR_DESC:-38;5;8;3}${rc}"
rst="${lc}0${rc}"

declare -A FZF_DEFAULT_ACTIONS
FZF_DEFAULT_ACTIONS[cat:id]="echo the item(s) first column"
FZF_DEFAULT_ACTIONS[cat:preview]="echo what is displayed in preview pane for item(s)"
FZF_DEFAULT_ACTIONS[yank:id]="yank the item(s) first column to the clipboard"
FZF_DEFAULT_ACTIONS[yank:preview]="yank the preview pane content for item(s) to the clipboard"

declare -A FZF_ACTIONS
for action in "${!FZF_DEFAULT_ACTIONS[@]}"; do
  is_set=${FZF_ACTIONS[$action]:-}
  if [[ -z $is_set ]]; then
    FZF_ACTIONS[$action]="${FZF_DEFAULT_ACTIONS[$action]}"
  fi
done

function action_menu_display {
  lines=()
  function action_menu_display_line {
    FZF_ACTIONS[$action]=${FZF_ACTIONS[$action]:-}
    desc="${FZF_ACTIONS[$action]}"
    lineout="${rst}${clr[action_id]}${action}"
    lineout="${lineout}|${clr[action_desc]}${desc}"
    lines+=("$lineout")
  }
  if [[ -n $FZF_ACTIONS_SORT ]]; then
    for action in "${FZF_ACTIONS_SORT[@]}"; do
      action_menu_display_line "$action"
    done
  else
    for action in "${!FZF_ACTIONS[@]}"; do
      action_menu_display_line "$action"
    done
  fi
  printf "%s\n" "${lines[@]}" | column -t -s'|'
}

function fzf_result_default {
  action="$1"
  item_id="$2"
  if [[ "$action" == "cat:id" ]]; then
    printf "%s\n" ${item_id}
  elif [[ "$action" == "cat:preview" ]]; then
    echo "Preview ${item_id}"
  elif [[ "$action" == "yank:id" ]]; then
    printf "%s\n" ${item_id} | xsel --append --clipboard
    echo "Copied ${item_id} to clipboard"
  elif [[ "$action" == "yank:preview" ]]; then
    echo "${item_id} to preview" | xsel --append --clipboard
    echo "Copied ${item_id} preview to clipboard "
  fi
}

function fzf_results_default {
  action="${1:-}" && shift
  selected_items=($@)
  for item in "${selected_items[@]}"; do
    item_id=$(echo "$item" | cut -d' ' -f1)
    fzf_result_default "$action" "$item_id"
  done
}

function action_menu {
  selected_items=($@)
  if [[ $FZF_RAW_OUT -eq 1 ]]; then
    action_menu_display
    exit 0
  fi
  if [ ${#selected_items[@]} -gt 1 ]; then
    header="Perform action on ${#selected_items[@]} items"
  else
    header="Perform action on: $(cut -d' ' -f1 <<<${selected_items[*]})"
  fi

  fzf_opts="--header-lines=0 --no-multi --header=\"$header\""
  fzf_opts="${fzf_opts} --preview-window=hidden --delimiter='\|' --with-nth=1.."
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $fzf_opts"
  # export FZF_DEFAULT_OPTS

  if [[ $FZF_TMUX -eq 1 ]]; then
    FZF_TMUX_OPTS="-w50% -h30%"
    IFS=$'\n' result=($(action_menu_display | fzf-tmux $FZF_TMUX_OPTS))
  else
    IFS=$'\n' result=($(action_menu_display | fzf))
  fi

  if [[ ${#result[@]} -eq 3 ]]; then
    query="$(echo ${result[0]} | xargs)"
    key="$(echo ${result[1]} | xargs)"
    selected_action=$(echo "${result[*]:2}" | cut -d' ' -f1)
  else
    query=""
    key="$(echo ${result[0]} | xargs)"
    selected_action=$(echo "${result[*]:1}" | cut -d' ' -f1)
  fi

  # if popout key pressed, toggle between fzf and fzf-tmux
  if [[ $key == 'ctrl-^' ]]; then
    if [[ $FZF_TMUX -eq 1 ]]; then
      FZF_TMUX=0
    else FZF_TMUX=1; fi
    menus+=(action_menu)
  elif [[ $key == 'enter' ]]; then
    if [[ $(type -t fzf_results 2>/dev/null) == 'function' ]]; then
      fzf_results "$selected_action" "${selected_items[@]}"
    else
      fzf_results_default "$selected_action" "${selected_items[@]}"
    fi
  elif [[ $key == 'esc' ]]; then
    debug "escaping ..."
    menus+=(main_menu)
  fi


}
