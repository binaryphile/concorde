concorde.array () {
  concorde.xtrace_begin
  printf -v __ 'declare %s=( %s )' "${1%%=*}" "${1#*=}"
  concorde.emit "$__"
  concorde.xtrace_end
}

concorde.defined () {
  declare -p "${1%%[*}" >/dev/null 2>&1 && [[ -n ${!1+x} ]]
}

concorde.emit () {
  concorde.xtrace_begin
  printf 'eval eval %q' "$1"
  concorde.xtrace_end
}

concorde.get () {
  concorde.xtrace_begin
  local space

  concorde.get_raw
  space=${__%%[^[:space:]]*}
  printf -v __ %s "${__#$space}"
  printf -v __ %s "${__//$'\n'$space/$'\n'}"
  concorde.xtrace_end
}

concorde.get_raw () {
  IFS=$'\n' read -rd '' __ ||:
}

concorde.hash () {
  concorde.xtrace_begin
  local name=${1%%=*}
  $(concorde.array value_ary="${1#*=}")
  local ary=()
  local item

  (( ! ${#value_ary[@]} )) && { concorde.emit "declare -A $name=()"; return ;}
  for item in "${value_ary[@]}"; do
    printf -v __ '[%s]=%q' "${item%%=*}" "${item#*=}"
    ary+=( "$__" )
  done
  concorde.emit "declare -A $name=( ${ary[*]} )"
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
  [[ $rc == 113 && -z $type ]] && { concorde.emit 'return 113'; return ;}
  [[ -z $type ]] && type=StandardError
  concorde.get <<'  EOS'
    __errcode=%q
    __errmsg=%q
    __errtype=%q
  EOS
  __+=$'\n'
  case $return in
    0 ) __+='( exit 113 )';;
    * ) __+='return 113'  ;;
  esac
  printf -v __ "$__" "$rc" "$msg" "$type"
  concorde.emit "$__"
  concorde.xtrace_end
}

concorde.repr_hash () {
  concorde.xtrace_begin
  local __name=$1
  local __ary=()
  local __item
  local __var

  __=$(declare -p "$__name" 2>/dev/null)  || $(concorde.raise ArgumentError)
  [[ ${__:9:1} == A ]]                    || $(concorde.raise TypeError    )
  printf -v __ '(( ${#%s[@]} )) && set -- "${!%s[@]}" || { __=''; return ;}' "$__name" "$__name"
  eval "$__"
  for __item in "$@"; do
    __var=$__name[$__item]
    printf -v __ '%s=%q' "$__item" "${!__var}"
    __ary+=( "$__" )
  done
  __=${__ary[*]}
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
