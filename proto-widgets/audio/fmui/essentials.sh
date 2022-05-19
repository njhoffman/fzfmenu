declare -p FMUI_ESSENTIALS_SH &>/dev/null && return
readonly FMUI_ESSENTIALS_SH


readonly GLOBAL='-g'
readonly ARRAY='-a'
readonly MAP='-A'
readonly IS_DIRECTORY='-d'
readonly IS_FILE='-f'
readonly IS_FIFO='-p'
readonly EXISTS='-e'


function lazy_declare {
  # declares a variable name if it does not exists
  # returns true / 0 if the variable was declared
  # (useful to make dependencies clearly visible
  #  without executing scripts multiple times)
  declare -p "$@" &>/dev/null
  local name_exists=$?

  (( $name_exists != 0 )) && {
    readonly "$@"
      return 0
    }

  return 1
}
