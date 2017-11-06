declare -Ag __module_hsh
{ [[ -n ${__module_hsh[concorde]:-} ]] && (( ! $# )) ;} && return

declare -Ag __id_hsh
[[ -z ${__next_id:-} ]] && __next_id=0

concorde.array () {
  concorde.xtrace_begin
  printf -v __ 'declare %s=( %s )' "${1%%=*}" "${1#*=}"
  concorde.emit "$__"
  concorde.xtrace_end
}

concorde.assign () {
  concorde.xtrace_begin
  [[ $2 == to ]] || { concorde.raise ArgumentError return=0; return ;}
  $(concorde.array arg_ary="$1")
  $(concorde.array var_ary="$3")
  local IFS=$IFS
  local count
  local statement_ary=()
  local var

  set -- "${arg_ary[@]}"
  count=${#var_ary[@]}
  (( $# > count )) && : $(( count-- ))
  for (( i = 0; i < count; i++ )); do
    printf -v __ 'declare %s=%q' "${var_ary[i]}" "$1"
    statement_ary+=( "$__" )
    shift
  done
  (( count != ${#var_ary[@]} )) && {
    concorde.escape_items "$@"
    printf -v __ 'declare %s=( %s )' "${var_ary[count]}" "$__"
    statement_ary+=( "$__" )
  }
  IFS=$'\n'
  concorde.emit "${statement_ary[*]}"
  concorde.xtrace_end
}

concorde.defined () {
  declare -p "${1%%[*}" >/dev/null 2>&1 && [[ -n ${!1+x} ]]
}

concorde.die () {
  local rc=$?
  concorde.xtrace_begin
  local errmsg
  local msg=''

  [[ -n ${1:-} && $1 != rc=* ]] && { msg=$1; shift ;}
  $(concorde.grabkw rc from "$@")
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
  concorde.xtrace_begin
  printf 'eval eval %q' "$1"
  concorde.xtrace_end
}

concorde.escape_items () {
  concorde.xtrace_begin
  printf -v __ '%q ' "$@"
  __=${__% }
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

concorde.grab () {
  concorde.xtrace_begin
  [[ $2 == from ]] || { concorde.raise ArgumentError return=0; return ;}
  $(concorde.array name_ary="$1")
  $(concorde.hash arg_hsh="$3"  )
  local IFS=$IFS
  local name
  local rc
  local statement_ary=()

  for name in "${name_ary[@]}"; do
    concorde.defined arg_hsh[$name] && rc=$? || rc=$?
    case $rc in
      0 ) printf -v __ 'declare %s=%q'                              "$name" "${arg_hsh[$name]}"   ;;
      * ) printf -v __ '! $(concorde.is_local %s) && declare %s=%q' "$name"  "$name" "${arg_hsh[$name]:-}" ;;
    esac
    statement_ary+=( "$__" )
  done
  statement_ary+=( : )
  IFS=$'\n'
  concorde.emit "${statement_ary[*]}"
  concorde.xtrace_end
}

concorde.grabkw () {
  concorde.xtrace_begin
  [[ $2 == from ]] || { concorde.raise ArgumentError return=0; return ;}
  { (( $# < 3 )) || [[ -z $3 ]] ;} && __='' || concorde.escape_items "${@:3}"
  concorde.grab "$1" from "$__"
  concorde.xtrace_end
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

concorde.hashkw () {
  concorde.xtrace_begin
  concorde.escape_items "$@"
  concorde.hash "$__"
  concorde.xtrace_end
}

concorde.is_local () {
  concorde.xtrace_begin
  concorde.get <<'  EOS'
    concorde.defined %s                        && \
      {
        (( ! ${#FUNCNAME[@]} ))       || \
          (
            declare -g %s=$'sigil\037'
            [[ $%s != $'sigil\037' ]] && \
              {
                unset -v %s
                ! concorde.defined %s
              }
          )
      }
  EOS
  printf -v __ "$__" "$1" "$1" "$1" "$1" "$1"
  concorde.emit "$__"
  concorde.xtrace_end
}

concorde.module () {
  concorde.xtrace_begin
  local name=$1; shift
  local depth=1
  $(concorde.grabkw depth from "$@")
  local bash_source
  local i
  local index
  local path=''
  local statement

  concorde.get <<'  EOS'
    { declare -p __module_hsh >/dev/null 2>&1 && [[ -n ${__module_hsh[%s]:-} && ${@:$#} != reload=1 ]] ;} && return
    declare -Ag __%s
    __%s[root]=$(
      type greadlink >/dev/null 2>&1 && readlink='greadlink -f --' || readlink='readlink -f --'
      $readlink "$(dirname -- "$($readlink "$BASH_SOURCE")")"%s
    )
    __module_hsh[%s]=__%s
    __id_hsh[%s]=%s
    __next_id=%s
  EOS
  statement=$__
  for (( i = 0; i < depth; i++ )); do path+=/..; done
  [[ ${FUNCNAME[1]} == module ]] && index=2 || index=1
  bash_source=${BASH_SOURCE[index]}
  case ${__id_hsh[$bash_source]:-} in
    '' )
      __=$__next_id
      __id_hsh[$bash_source]=$__
      (( __next_id++ )) ||:
      ;;
    * ) __=${__id_hsh[$bash_source]};;
  esac
  printf -v statement "$statement" "$name" "$__" "$__" "$path" "$name" "$__" "$bash_source" "$__" "$__next_id"
  concorde.emit "$statement"
  concorde.xtrace_end
}

concorde.parse_options () {
  concorde.xtrace_begin
  $(concorde.ssv input_ary="$1"); shift
  local -A option_hsh=()
  local -A result_hsh=()
  local arg_ary=()
  local input
  local name
  local option
  local statement

  for input in "${input_ary[@]}"; do
    $(concorde.assign "$input" to 'short long argument help')
    short=${short#-}
    long=${long#--}
    long=${long//-/_}
    [[ -n $long ]] && name=$long || name=$short
    concorde.stuff 'argument name help' into ''
    [[ -n $short  ]] && option_hsh[$short]=$__
    [[ -n $long   ]] && option_hsh[$long]=$__
  done

  while (( $# )); do
    case $1 in
      --*=*   ) set -- "${1%%=*}" "${1#*=}" "${@:2}";;
      -[^-]?* )
        [[ $1 =~ ${1//?/(.)} ]]
        set -- $(printf -- '-%s ' "${BASH_REMATCH[@]:2}") "${@:2}"
        ;;
    esac
    option=${1#-}
    option=${option#-}
    option=${option//-/_}
    [[ $1 =~ ^-{1,2}[^-] && -n ${option_hsh[$option]:-} ]] && {
      $(concorde.grab 'argument name' from "${option_hsh[$option]}")
      case $argument in
        ''  ) result_hsh["$name"_flag]=1       ;;
        *   ) result_hsh[$argument]=$2; shift  ;;
      esac
      shift
      continue
    }
    case $1 in
      --  ) shift; arg_ary+=( "$@" ); break                                             ;;
      -*  ) concorde.raise OptionError "unsupported option '$1'" return=0 rc=1; return  ;;
      *   ) arg_ary+=( "$@" ); break                                                    ;;
    esac
    shift
  done
  case ${#arg_ary[@]} in
    0 ) statement='set --';;
    * )
      concorde.escape_items "${arg_ary[@]}"
      printf -v statement 'set -- %s' "$__"
      ;;
  esac
  concorde.repr_hash result_hsh
  printf -v statement '%s\n__=%q' "${statement:-}" "$__"
  concorde.emit "$statement"
  concorde.xtrace_end
}

concorde.part () {
  concorde.xtrace_begin
  [[ $2 == on ]] || $(concorde.raise ArgumentError)
  local oldIFS=$IFS
  local IFS=$3
  local glob
  local result_ary=()

  [[ $- == *f* ]] && glob=$? || glob=$?
  set -o noglob
  result_ary=( $1 )
  (( glob )) && set +o noglob
  IFS=$oldIFS
  concorde.repr_array result_ary
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

concorde.repr_array () {
  concorde.xtrace_begin
  local __name=$1
  local __ary=()
  local __item

  __=$(declare -p "$__name" 2>/dev/null)  || $(concorde.raise ArgumentError)
  [[ ${__:9:1} == a ]]                    || $(concorde.raise TypeError    )
  printf -v __ '(( ${#%s[@]} )) && set -- "${%s[@]}" || { __=''; return ;}' "$__name" "$__name"
  eval "$__"
  for __item in "$@"; do
    printf -v __ %q "$__item"
    __ary+=( "$__" )
  done
  __=${__ary[*]}
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

concorde.source_relative () {
  concorde.xtrace_begin
  local module_name=$1
  local file
  local index
  local path
  local readlink

  [[ $module_name == /*  ]] && { concorde.raise ArgumentError return=0; return ;}
  [[ $module_name != */* ]] && { concorde.raise ArgumentError return=0; return ;}
  type greadlink >/dev/null 2>&1 && readlink='greadlink -f --' || readlink='readlink -f --'
  for (( index = 1; index < ${#FUNCNAME}; index++ )); do
    [[ ${FUNCNAME[index]} != *"${FUNCNAME##*.}" ]] && break
  done
  file=$(dirname -- "$($readlink "${BASH_SOURCE[index]}")")/$module_name
  [[ -e $file ]] || { concorde.raise FileNotFoundError return=0; return ;}
  concorde.emit "source '$file'"
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

concorde.ssv () {
  concorde.xtrace_begin
  concorde.part "${1#*=}" on $'\n'
  concorde.array "${1%%=*}=$__"
  concorde.xtrace_end
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
  concorde.get <<'  EOS'
    set %so errexit
    set %so errtrace
    set %so nounset
    set %so pipefail

    trap %s ERR
  EOS
  printf -v __ "$__" "$option" "$option" "$option" "$option" "$callback"
  eval "$__"
  concorde.xtrace_end
}

concorde.stuff () {
  concorde.xtrace_begin
  [[ $2 == into ]] || $(concorde.raise ArgumentError)
  local __item

  $(concorde.hash __hash="$3")
  for __item in $1; do
    __hash[$__item]=${!__item}
  done
  concorde.repr_hash __hash
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
  local xtrace

  exit=1
  xtrace=0
  $(concorde.grabkw 'exit xtrace' from "$@")
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
