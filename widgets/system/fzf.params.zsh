#!/bin/zsh

SOURCE="${(%):-%N}"
CWD="$(cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd)"
FZF_LIB="$CWD/../../fzf-lib"

FZF_ACTIONS=(
  "unset"
)

FZF_ACTION_DESCRIPTIONS=(
  "unset the assignment"
)

_fzf-assign-vars() {
  local lc=$'\e[' rc=m
  _clr[id]="${lc}${CLR_ID:-38;5;30}${rc}"
  _clr[export]="${lc}${CLR_EXPORT:-38;5;75;1}${rc}"
  _clr[export_val]="${lc}${CLR_EXPORT_VAL:-38;5;74}${rc}"
  _clr[local]="${lc}${CLR_LOCAL:-38;5;239}${rc}"
  _clr[icon]="${lc}${CLR_ICON:-38;5;249}${rc}"

}

_fzf-extra-opts() {
   opts="--delimiter='\|'"
  # opts="${opts} --nth=1,2,3,-1"
  echo "$opts"
}


_fzf-source() {
  for __param in "${(iok)parameters[@]}"; do
    __aparam=() __atype=() __avalue=() __tpe="${(Pt)__param}" __pdiff=0 __tdiff=0
      __lparam=$(echo "$__param" | sed 's/\n//g')

      if [[ $__lparam = hist* ]]; then
        continue
      # elif [[ $__lparam = HIST_ ]]; then
      #   continue
      elif [[ $__lparam = *_history_substring_sea* ]]; then
        continue
      fi

      local icon="X"
      local -a elems

      # local txt
      if [[ "${(Pt)__param}" = *association* ]]; then
        __tpe="${__tpe/association/}"
        elems=( "${(Pkv@)__param}" )
        elems=( "${(@)elems[1,50]}" )
        elems=( "${(qq)elems[@]}" )
        txt="${elems[*]}"
        # txt="${txt[1,300]}"
        # -zui_std_special_text "$txt" __avalue
      elif [[ "${(Pt)__param}" = *array* ]]; then
        __tpe="${__tpe/array/}"
        elems=( "${(P@)__param}" )
        elems=( "${(@)elems[1,50]}" )
        elems=( "${(qq)elems[@]}" )
        txt="${elems[*]}"
        icon=""
        # txt="${txt[1,300]}"
        # -zui_std_special_text "$txt" __avalue
      elif [[ "${(Pt)__param}" = *integer* ]]; then
        __tpe="${__tpe/integer/}"
        icon=""
        txt="${(P)__param}"
        txt="${(qq)txt}"
      elif [[ "${(Pt)__param}" = *float* ]]; then
        __tpe="${__tpe/float/}"
        icon=""
        txt="${(P)__param}"
        txt="${(qq)txt}"
      else
        local icon=""
        __tpe="${__tpe/scalar/}"
        txt="${(P)__param}"
        txt="${(qq)txt}"
      fi

      icon="${_clr[icon]}${icon}${_clr[rst]}"
      if [[ "$__tpe" = *tied* ]]; then
        icon=" ${icon}"
      elif [[ "$__tpe" = *special* ]]; then
        icon=" ${icon}"
      else
        icon="  ${icon}"
      fi

      __tpe="${__tpe/tied/}"
      __tpe="${__tpe/special/}"
      __tpe="${__tpe#-}"

      if [[ "$__tpe" = *readonly* ]]; then
        __tpe="${__tpe/readonly/}"
        icon=" ${icon}"
      else
        icon="  ${icon}"
      fi

      __tpe="${__tpe#-}"

      if [[ "$__tpe" = *hide* ]]; then
        __tpe="${__tpe/hide-hideval/}"
        __tpe="${__tpe/hideval/}"
        icon=" ${icon}"
      else
        icon="  ${icon}"
      fi

      txt=$(echo ${txt} | tr '\n' ' ' | tr "'" " ")
      txt="${txt[1,100]}"

      (( ${#__lparam} <= 25 )) && __pdiff=$(( 25 - ${#__lparam} )) || __lparam="${__lparam[1,23]}...";

      if [[ "$__tpe" = *export* ]]; then
        __lparam="${_clr[export]}${__lparam}${_clr[rst]}"
        txt="${_clr[export_val]}${txt}${_clr[rst]}"
        __tpe="${__tpe/export/}"
      fi

      if [[ "$__tpe" = *local* ]]; then
        __lparam="${_clr[local]}${__lparam}${_clr[rst]}"
        __tpe="${__tpe/local/}"
      fi
      # TODO: unique
      __tpe="${__tpe/unique/}"
      __tpe="${__tpe#-}"

      # reply+=( "${__aparam[1]}${(r:__pdiff+1:: :)__space} ${__atype[1]}${(r:__tdiff+1:: :)__space} ${__avalue[1]}" )
      echo -e "${icon}|${__lparam}|${__tpe}|${txt}|"
      # echo -e "${icon}|${__lparam}|${txt}|"

  done | column -s'|' -t
}

_fzf-prompt() {
  echo " env❯ "
}

_fzf-preview() {
  # echo "$2" | tr -d '()' \
  #   | awk '{printf "%s ", $2} {print $1}' \
  #   | xargs -r man \
  #   | col -bx \
  #   | bat --theme "$theme" -l man -p --color always
    # | tr -d '()'
    # | awk '{printf "%s ", $2} {print $1}'
}

# FZF_RAW_OUT=1

source "$FZF_LIB.zsh"

_fzf-unset
