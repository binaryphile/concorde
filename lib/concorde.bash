declare -Ag __hmodules
[[ -v __hmodules[concorde] ]] && return

__code=113
__dir=$(dirname -- "$(readlink --canonicalize -- "${BASH_SOURCE[1]}")")
readonly __dir

die () {
  local rc=$?
  concorde.xtrace_begin
  local errmsg
  local msg=''

  [[ -n ${1:-} && $1 != rc=* ]] && { msg=$1; shift ;}
  [[ ${1:-} == rc=* ]] && rc=${1#rc=}
  (( rc == 113 )) && {
    case $msg in
      '' )
        case $__errmsg in
          '' ) errmsg="$__errtype: return code $__errcode"             ;;
          *  ) errmsg="$__errtype: $__errmsg (return code $__errcode)" ;;
        esac
        ;;
      * ) errmsg=$msg;;
    esac
    case $__errcode in
      0 ) printf '%s\n' "$errmsg"     ;;
      * ) printf '%s\n' "$errmsg" >&2 ;;
    esac
    exit "$rc"
  }
  [[ -z $msg ]] && exit "$rc"
  case $rc in
    0 ) printf '%s\n' "$msg"    ;;
    * ) printf '%s\n' "$msg" >&2;;
  esac
  exit "$rc"
}

concorde.emit () {
  printf 'eval eval %q' "$1"
}

except () {
  [[ -n $__errtype ]] && "$@"
  __code=113
  __errtype=''
  __errcode=''
  __errmsg=''
}

module () {
  concorde.xtrace_begin
  __="
    { [[ -v __hmodules[$1] && \${2:-} != reload=1 ]] ;} && return
    __hmodules[$1]=
  "
  concorde.emit "$__"
  concorde.xtrace_end
}

raise () {
  local rc=$?
  concorde.xtrace_begin
  local type=''
  local msg=''
  local return=1

  [[ -n ${1:-} && $1 != rc=?* && $1 != return=?* ]] && { type=$1; shift ;}
  [[ -n ${1:-} && $1 != rc=?* && $1 != return=?* ]] && { msg=$1 ; shift ;}
  while (( $# )); do
    case $1 in
      rc=*      ) rc=${1#rc=}         ;;
      return=*  ) return=${1#return=} ;;
    esac
    shift
  done
  [[ -z $type && $return != 0 ]] && {
    [[ -n $__errtype ]] && {
      concorde.emit "return $__code"
      return
    }
    type=StandardError
  }
  __=$'
    __errcode=%q
    __errmsg=%q
    __errtype=%q\n
  '
  case $return in
    0 ) __+="(exit $__code)";;
    * ) __+="return $__code";;
  esac
  case $type in
    ''  ) printf -v __ "$__" "$__errcode" "$__errmsg" "$__errtype";;
    *   ) printf -v __ "$__" "$rc"        "$msg"      "$type"     ;;
  esac
  concorde.emit "$__"
  concorde.xtrace_end
}

sourced () {
  [[ ${FUNCNAME[1]} == source ]]
}

strict_mode () {
  concorde.xtrace_begin
  local status=$1
  local callback
  local option

  case $status in
    on      ) option=-; callback=concorde.traceback ;;
    off     ) option=+; callback=-                  ;;
    *       ) $(concorde.raise ArgumentError)       ;;
  esac
  __='
    set %so errexit
    set %so errtrace
    set %so nounset
    set %so pipefail

    trap %s ERR
  '
  printf -v __ "$__" "$option" "$option" "$option" "$option" "$callback"
  eval "$__"
  concorde.xtrace_end
}

concorde.traceback () {
  local rc=$?
  set +o xtrace
  local errcode
  local errmsg
  local errtype
  local exit_flag
  local frame
  local val
  local xtrace_flag=0

  exit_flag=1
  while (( $# )); do
    case $1 in
      exit=*    ) exit_flag=${1#exit=}    ;;
      xtrace=*  ) xtrace_flag=${1#xtrace=};;
    esac
    shift
  done
  (( xtrace_flag )) && set -o xtrace
  strict_mode off
  case $rc in
    113 )
      errtype=$__errtype
      errmsg=$__errmsg
      errcode=$__errcode
      ;;
    * )
      errtype=StandardError
      errmsg='Unspecified Error'
      errcode=$rc
      ;;
  esac
  case $errmsg in
    ''  ) printf $'\nTraceback:\n\n'"  $errtype: return code $errcode" >&2          ;;
    *   ) printf $'\nTraceback:\n\n'"  $errtype: $errmsg (return code $errcode)" >&2;;
  esac
  frame=0
  while val=$(caller "$frame"); do
    set -- $val
    (( frame == 0 )) && { printf '  Command: '; sed -n "$1"' s/^[[:space:]]*// p' "$3" ;} >&2
    (( ${#3} > 80 )) && set -- "$1" "$2" "${3:0:35}"[...]"${3:${#3}-40}"
    printf "  %s:%s:in '%s'\n" "$3" "$1" "$2" >&2
    (( frame++ ))
  done
  (( exit_flag )) && exit 1
}

try () {
  __code=0
  "$@"
}

concorde.xtrace_begin () {
  (( ${__xtrace:-} )) && return
  [[ $- != *x* ]] && __xtrace_set=$? || __xtrace_set=$?
  set +o xtrace
}

concorde.xtrace_end () {
  (( ${__xtrace_set:-} )) && set -o xtrace;:
}

$(module concorde)
