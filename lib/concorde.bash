[[ -n ${__ns:-} && ${1:-} != 'reload=1' ]] && return
[[ ${1:-} == 'reload=1' ]] && shift
type -P greadlink >/dev/null 2>&1 && __ns=g || __ns=''
__ns="[concorde]=\"[root]=\\\"$(
  ${__ns}readlink -f -- "$(dirname "$(${__ns}readlink -f -- "$BASH_SOURCE")")"/..
)\\\" [macros]=\\\"[readlink]=\\\\\\\"${__ns}readlink -f --\\\\\\\"\\\"\""

unset -v CDPATH

assign () {
  [[ $2 == to ]] || return
  $(local_ary args=$1)
  $(local_ary vars=$3)
  local count
  local statement=''
  local var

  set -- "${args[@]}"
  count=${#vars[@]}
  (( $# > count )) && : $(( count-- ))
  for (( i = 0; i < count; i++ )); do
    printf -v statement '%sdeclare %s=%q\n' "$statement" "${vars[i]}" "$1"
    shift
  done
  (( count == ${#vars[@]} )) && { emit "$statement"; return ;}
  printf -v __ '%q ' "$@"
  printf -v statement '%sdeclare -a %s=( %s )\n' "$statement" "${vars[count]}" "$__"
  emit "$statement"
}

bring () {
  [[ $2 == from ]] || return
  is_literal "$1" && eval "local -a function_ary=$1" || local -a function_ary=( $1 )
  local spec=$3
  local feature

  eval "$(
    $(load "$spec")
    feature=${spec##*/}
    feature=${feature%.*}
    is_feature "$feature" && $(grab dependencies fromns "$feature")
    [[ -n ${dependencies:-} ]] && {
      $(local_ary dependency_ary=$dependencies)
      function_ary+=( "${dependency_ary[@]}" )
    }
    repr function_ary
    __extract_functions __
    put "$__"
  )"
}

die () {
  local rc=${2:-$?}

  [[ -z ${1:-} ]] && exit "$rc"
  case $rc in
    0 ) put     "$1";;
    * ) puterr  "$1";;
  esac
  exit "$rc"
}

emit () { printf 'eval eval %q\n' "$1" ;}

escape_ary () {
  local i
  local result_ary=()

  result_ary=( "$@" )
  for (( i = 0; i < $#; i++ )); do
    printf -v result_ary[i] %q "${result_ary[i]}"
  done
  repr result_ary
}

escape_items  () { printf -v __ '%q ' "$@"; __=${__% }  ;}

__extract_function () {
  local function=$1
  local IFS=$'\n'

  set -- $(type "$function")
  shift
  printf -v __ '%s\n' "$@"
}

__extract_functions () {
  $(local_ary function_ary=$1)
  local function
  local result=''

  for function in "${function_ary[@]}"; do
    __extract_function "$function"
    result+=$__
  done
  __=$result
}

get () {
  local space

  get_raw
  space=${__%%[^[:space:]]*}
  printf -v __ %s "${__:${#space}}"
  printf -v __ %s "${__//$'\n'$space/$'\n'}"
}

get_raw () { IFS=$'\n' read -rd '' __ ||: ;}

grab () {
  [[ $2 == 'fromns' ]] && { grab "$1" from __ns."${@:3}"; return ;}
  [[ $2 == 'from'   ]] || return
  local name=$1
  shift 2
  $(local_hsh arg_hsh="$@")
  case $name in
    '*'     ) local -a var_ary=( "${!arg_hsh[@]}" ) ;;
    *       ) local -a var_ary=( $name            ) ;;
  esac
  local statement=''
  local var

  ! (( ${#var_ary[@]} )) && return
  for var in "${var_ary[@]}"; do
    if is_set arg_hsh["$var"]; then
      printf -v statement '%sdeclare %s=%q\n' "${statement:-}" "$var" "${arg_hsh[$var]:-}"
    else
      ! is_set "$var" && printf -v statement '%sdeclare %s=%q\n' "${statement:-}" "$var" "${arg_hsh[$var]:-}"
    fi
  done
  emit "$statement"
}

instantiate () { printf -v "$1" %s "$(eval "echo ${!1}")" ;}

is_dotted () {
  local value=$1
  local item

  [[ $value == *.* ]] || return
  part "$value" on .
  $(local_ary value_ary=__)
  for item in "${value_ary[@]}"; do
    is_identifier "$item" || return
  done
}

is_feature () {
  $(grab "$1" from __ns)
  is_set "$1"
}

is_identifier () { [[ $1 =~ ^[_[:alpha:]][_[:alnum:]]*$ ]] ;}
is_literal    () { [[ $1 == '('*')'                     ]] ;}

is_set () {
  declare -p "${1%%[*}" >/dev/null 2>&1 || return
  [[ -n ${!1+x} ]]
}

feature () {
  local feature_name=$1; shift
  local depth=1
  (( $# )) && $(grab depth from "$@")
  local i
  local path=''
  local statement

  get <<'  EOS'
    (
      eval declare -A ns_hsh=( ${__ns:-} )
      [[ -n ${ns_hsh[%s]:-} ]] && ! (( ${__reload:-} ))
    ) && return
    __ns=$(
      type -P greadlink >/dev/null 2>&1 && readlink='greadlink -f --' || readlink='readlink -f --'
      %s="[root]=\\"$($readlink "$(dirname "$($readlink "$BASH_SOURCE")")"%s)\\""
      stuff %s into "${__ns:-}"
      echo "$__"
    )
    ! (( ${__reload:-} )) || unset -v __reload
  EOS
  statement=$__
  (( depth )) && for (( i = 0; i < depth; i++ )); do path+=/..; done
  printf -v statement "$statement" "$feature_name" "$feature_name" "$path" "$feature_name"
  emit "$statement"
}

load () { require "$1" reload=1 ;}

local_ary () {
  [[ $1 == *=* ]] || return
  local first=$1; shift
  local ary=()
  local name
  local value

  name=${first%%=*}
  set -- "${first#*=}" "$@"
  value=$*
  is_set "$value" && value=${!value}
  emit "declare -a $name=( $value )"
}

local_hsh () {
  local item
  local name
  local result=''
  local value

  (( $# )) || return
  name=${1%%=*}
  value=${1#*=}
  shift
  set -- "$value" "$@"
  [[ $* == '['* || -z $* ]] && { value=$*; set -- ;}
  is_dotted "$value" && {
    item=${value%.*}
    value=${value##*.}
    $(grab "$value" from "$item")
  }
  is_set "$value" && { value=${!value}; shift ;}
  [[ $value == '['* || -z $value ]] && {
    ! (( $# )) || return
    escape_items "$value"
    emit "eval declare -A $name=( $__ )"
    return
  }
  for item in "$@"; do
    [[ $item == *?=* ]] || return
    printf -v result '%s [%s]=%q' "$result" "${item%%=*}" "${item#*=}"
  done
  emit "eval 'declare -A $name=( $result )'"
}

local_nry () {
  [[ $1 == *=* ]] || return
  local first=$1; shift
  local IFS=$IFS
  local ary=()
  local item
  local name
  local value

  name=${first%%=*}
  set -- "${first#*=}" "$@"
  value=$*
  is_set "$value" && value=${!value}
  IFS=$'\n'
  set -- $value
  ary=()
  for item in "$@"; do
    ary+=( "$(printf %q "$item")" )
  done
  emit "declare -a $name=( ${ary[*]} )"
}

log () { put "$@" ;}

member_of () {
  $(local_ary set_ary="${@:1:$#-1}")
  value="${@: -1}"
  local IFS

  IFS=$'\037'
  [[ $IFS"${set_ary[*]}"$IFS == *"$IFS$value$IFS"* ]]
}

parse_options () {
  $(local_nry input_ary="$1"); shift
  local -A option_hsh=()
  local -A result_hsh=()
  local arg_ary=()
  local input
  local name
  local option
  local statement

  for input in "${input_ary[@]}"; do
    $(assign input to 'short long argument help')
    short=${short#-}
    long=${long#--}
    long=${long//-/_}
    [[ -n $long ]] && name=$long || name=$short
    stuff 'argument name help' into ''
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
      $(grab 'argument name' from "${option_hsh[$option]}")
      case $argument in
        ''  ) result_hsh["$name"_flag]=1       ;;
        *   ) result_hsh[$argument]=$2; shift  ;;
      esac
      shift
      continue
    }
    case $1 in
      '--'  ) shift                           ; arg_ary+=( "$@" ); break  ;;
      -*    ) puterr "unsupported option $1"  ; return 1                  ;;
      *     ) arg_ary+=( "$@" )               ; break                     ;;
    esac
    shift
  done
  case ${#arg_ary[@]} in
    '0' ) statement='set --';;
    *   )
      escape_items "${arg_ary[@]}"
      printf -v statement 'set -- %s' "$__"
      ;;
  esac
  repr result_hsh
  printf -v statement '%s\n__=%q' "${statement:-}" "$__"
  emit "$statement"
}

part () {
  [[ $2 == on ]] || return
  local IFS=$3
  local result_ary=()

  result_ary=( $1 )
  unset -v IFS
  repr result_ary
}

put     () { printf '%s\n' "$@"   ;}
puterr  () { put "Error: $1" >&2  ;}

raise () {
  local rc=$?

  [[ -n ${1:-} ]] && puterr "$1"
  emit "return ${2:-$rc}"
}

repr () {
  local _ary=()
  local item

  __=$(declare -p "$1" 2>/dev/null) || return
  [[ ${__:9:1} != a ]] && {
    __=${__#*=}
    [[ $__ == \'*\' ]] && eval "__=$__"
    __=${__#\(}
    __=${__%\)}
    __=${__% }
    return
  }
  eval '(( ${#'"$1"'[@]} )) && set -- "${'"$1"'[@]}" || set --'
  for item in "$@"; do
    _ary+=( "$(printf %q "$item")" )
  done
  (( ${#_ary[@]} )) && __=${_ary[*]} || __=''
}

require () {
  local spec=$1; shift
  local __reload
  [[ ${@:$#} == reload=1 ]] && { __reload=1; set -- "${@:0:$#}" ;}
  local oldIFS=$IFS
  local IFS=$IFS
  local extension
  local extension_ary=()
  local item
  local file
  local path

  extension_ary=(
    .bash
    .sh
    ''
  )
  case $spec in
    /* )
      path=${spec%/*}
      spec=${spec##*/}
      ;;
    * ) path=$PATH;;
  esac
  IFS=:
  for item in $path; do
    for extension in "${extension_ary[@]}"; do
      [[ -e $item/$spec$extension ]] && break 2
    done
  done
  IFS=$oldIFS
  file=$item/$spec$extension
  [[ -e $file ]] || return
  (( $# )) && emit "source $file $*" || emit "source $file"
}

require_relative () {
  local spec=$1; shift
  local caller_dir
  local extension
  local extension_ary=()
  local file

  $(grab readlink fromns concorde.macros)

  extension_ary=(
    .bash
    .sh
    ''
  )
  [[ $spec != /* && $spec == *?/* ]] || return
  caller_dir=$($readlink "$(dirname "$($readlink "${BASH_SOURCE[1]}")")")
  file=$caller_dir/$spec
  for extension in "${extension_ary[@]}"; do
    [[ -e $file$extension ]] && break
  done
  file=$file$extension
  [[ -e $file ]] || return
  (( $# )) && emit "source $file $*" || emit "source $file"
}

sourced () { [[ ${FUNCNAME[1]} == 'source' ]] ;}

strict_mode () {
  local status=$1
  local IFS=$IFS
  local callback
  local option
  local statement

  case $status in
    'on'  ) option=-; callback=traceback  ;;
    'off' ) option=+; callback=-          ;;
    *     ) return 1                      ;;
  esac
  get <<'  EOS'
    set %so errexit
    set %so errtrace
    set %so nounset
    set %so pipefail

    trap %s ERR
  EOS
  printf -v statement "$__" "$option" "$option" "$option" "$option" "$callback"
  eval "$statement"
}

stuff () {
  [[ $2 == intons ]] && {
    [[ -z ${__ns:-} ]] && __ns=''
    __stuffrec "$1" __ns"${3+.}${3:-}"
    __ns=$__
    return
  }
  [[ $2 == into ]] || return
  ! is_set "$1" && eval "local -a ref_ary=( $1 )" || local -a ref_ary=( "$1" )
  $(local_hsh result_hsh=$3)
  local ref

  for ref in "${ref_ary[@]}"; do
    result_hsh[$ref]=${!ref}
  done
  repr result_hsh
}

__stuffrec () {
  [[ $2 != *.* ]] && { stuff "$1" into "$2"; return ;}
  local child
  local parent

  parent=${2%%.*}
  set -- "$1" "${2#*.}"
  child=${2%%.*}
  $(grab "$child" from "$parent")
  __stuffrec "$1" "$2"
  printf -v "$child" %s "$__"
  stuff "$child" into "$parent"
}

traceback () {
  set +o xtrace
  local frame
  local val

  strict_mode off
  printf '\nTraceback:  '
  frame=0
  while val=$(caller "$frame"); do
    set -- $val
    (( frame == 0 )) && sed -n "$1"' s/^[[:space:]]*// p' "$3"
    (( ${#3} > 30 )) && set -- "$1" "$2" [...]"${3:${#3}-25:25}"
    printf "  %s:%s:in '%s'\n" "$3" "$1" "$2"
    : $(( frame++ ))
  done
  exit 1
}

update () {
  [[ $2 == 'with' ]] || return
  $(local_hsh original_hsh=$1 )
  $(local_hsh update_hsh=$3   )
  local key

  for key in "${!update_hsh[@]}"; do
    original_hsh[$key]=${update_hsh[$key]}
  done
  repr original_hsh
}

wed () {
  [[ $2 == 'with' ]] || return
  $(local_ary original_ary=$1)
  local IFS=$3

  __="${original_ary[*]}"
}

with () { repr "$1"; grab '*' from "$__" ;}

concorde_init () {
  local -A macro_hsh=()
  local key_ary=()

  macro_hsh=(
    [cptree]='cp -r --'
    [install]='install -bm 644 --'
    [installd]='install -dm 755 --'
    [installx]='install -bm 755 --'
    [ln]='ln -sf --'
    [mkdir]='mkdir -p --'
    [mktemp]="mktemp -q --"
    [mktempd]="mktemp -qd --"
    [rm]='rm -f --'
    [rmdir]='rmdir --'
    [rmtree]='rm -rf --'
    [sed]='sed -i.bak'
  )
  $(with macro_hsh)
  key_ary=( "${!macro_hsh[@]}" )
  repr key_ary
  stuff "$__" intons concorde.macros
}

concorde_init
unset -f concorde_init
