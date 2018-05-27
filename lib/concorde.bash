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

concorde.xtrace_begin () {
  (( ${__xtrace:-} )) && return;:
  [[ $- != *x* ]] && __xtrace_set=$? || __xtrace_set=$?
  set +o xtrace
}

concorde.xtrace_end () {
  (( ${__xtrace_set:-} )) && set -o xtrace;:
}
