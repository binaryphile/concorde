declare -Ag __module_hsh
[[ -n ${__module_hsh[concorde]:-} ]] && return

declare -Ag __id_hsh
[[ -z ${__next_id:-} ]] && __next_id=0

concorde.die () {
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

concorde.module () {
  concorde.xtrace_begin
  local name=$1; shift
  local depth
  local bash_source
  local i
  local index
  local path=''
  local statement

  depth=1
  while (( $# )); do
    case $1 in
      depth=* ) depth=${1#depth=};;
    esac
    shift
  done
  statement='
    { declare -p __module_hsh &>/dev/null && [[ -n ${__module_hsh[%s]:-} && ${@:$#} != reload=1 ]] ;} && return
    declare -Ag __%s
    __%s[root]=$(
      type greadlink &>/dev/null && readlink='\''greadlink -f --'\'' || readlink='\''readlink -f --'\''
      $readlink "$(dirname -- "$($readlink "$BASH_SOURCE")")"%s
    )
    __module_hsh[%s]=__%s
    __id_hsh[%s]=%s
    __next_id=%s
  '
  for (( i = 0; i < depth; i++ )); do path+=/..; done
  [[ ${FUNCNAME[1]} == module ]] && index=2 || index=1
  bash_source=${BASH_SOURCE[index]}
  case ${__id_hsh[$bash_source]:-} in
    '' )
      __=$__next_id
      __id_hsh[$bash_source]=$__
      (( __next_id++ ))
      ;;
    * ) __=${__id_hsh[$bash_source]};;
  esac
  printf -v statement "$statement" "$name" "$__" "$__" "$path" "$name" "$__" "$bash_source" "$__" "$__next_id"
  concorde.emit "$statement"
  concorde.xtrace_end
}

concorde.raise () {
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
    [[ $rc == 113 ]] && {
      concorde.emit 'return 113'
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
    0 ) __+='(exit 113)';;
    * ) __+='return 113';;
  esac
  case $type in
    ''  ) printf -v __ "$__" "$__errcode" "$__errmsg" "$__errtype";;
    *   ) printf -v __ "$__" "$rc"        "$msg"      "$type"     ;;
  esac
  concorde.emit "$__"
  concorde.xtrace_end
}

concorde.sourced () {
  concorde.xtrace_begin
  local index

  case ${FUNCNAME[1]} in
    sourced|'sourced?'  ) index=2;;
    *                   ) index=1;;
  esac
  concorde.xtrace_end
  [[ ${FUNCNAME[index]} == source   ]]
}

concorde.strict_mode () {
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
  local exit
  local frame
  local val
  local xtrace=0

  exit=1
  while (( $# )); do
    case $1 in
      exit=*    ) exit=${1#exit=}     ;;
      xtrace=*  ) xtrace=${1#xtrace=} ;;
    esac
    shift
  done
  (( xtrace )) && set -o xtrace
  concorde.strict_mode off
  case $rc in
    113 )
      errtype=$__errtype
      errmsg=$__errmsg
      errcode=$__errcode
      ;;
    * )
      errtype=CommandError
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
  (( exit )) && exit 1
}

concorde.xtrace_begin () {
  (( ${__xtrace:-} )) && return;:
  [[ $- != *x* ]] && __xtrace_set=$? || __xtrace_set=$?
  set +o xtrace
}

concorde.xtrace_end () {
  (( ${__xtrace_set:-} )) && set -o xtrace;:
}

$(concorde.module concorde)
