[[ -n ${__ns:-} && ${1:-} != 'reload' ]] && return
[[ ${1:-} == 'reload' ]] && shift
type -P greadlink >/dev/null 2>&1 && __ns=g || __ns=''
__ns="( [features]=\"( [concorde]=\\\"( [root]=\\\\\\\"$(
  ${__ns}readlink -f -- "$(dirname "$(${ns}readlink -f -- "$BASH_SOURCE")")"/..
)\\\\\\\" )\\\" )\" [macros]=\"( [readlink]=\\\"${ns}readlink -f --\\\")\" )"

unset -v CDPATH

assign () {
  [[ $2 == 'to' ]] || return
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

bring () { (
  [[ $2 == 'from' ]]  || return
  is_literal "$1"     && eval "local -a function_ary=$1" || local -a function_ary=( "$1" )
  local spec=$3
  local feature

  $(require "$spec")
  feature=${spec##*/}
  feature=${feature%.*}
  is_feature "$feature" && $(grab dependencies from_feature "$feature")
  [[ -n ${dependencies:-} ]] && {
    $(local_ary dependency_ary=$dependencies)
    function_ary+=( "${dependency_ary[@]}" )
  }
  repr function_ary
  _extract_functions __
  emit "$__"
) }

die () {
  local rc=$?

  [[ -n ${1:-} ]] && puterr "$1"
  exit "${2:-$rc}"
}

emit          () { printf 'eval eval %q\n' "$1"         ;}
escape_items  () { printf -v __ '%q ' "$@"; __=${__% }  ;}

_extract_function () {
  local function=$1
  local IFS=$'\n'

  set -- $(type "$function")
  shift
  printf -v __ '%s\n' "$@"
}

_extract_functions () {
  $(local_ary function_ary=$1)
  local function
  local result

  for function in "${function_ary[@]}"; do
    _extract_function "$function"
    result+=$__
  done
  repr result
}

get_ary () {
  local result_ary=()

  IFS=$'\n' read -rd '' -a result_ary ||:
  repr result_ary
}

get_here_ary () {
  get_here_str
  get_ary <<<"$__"
}

get_here_str () {
  local space

  get_str
  space=${__%%[^[:space:]]*}
  printf -v __ %s "${__:${#space}}"
  printf -v __ %s "${__//$'\n'$space/$'\n'}"
}

get_str () { IFS=$'\n' read -rd '' __ ||:         ;}

grab () {
  [[ $2 == 'from_ns' || $2 == 'from' ]] || return
  [[ $2 == 'from_ns' ]] && $(grab "$3" from __ns)
  $(local_hsh arg_hsh=$3)
  case $1 in
    '('*')' ) eval "local -a var_ary=$1"            ;;
    '*'     ) local -a var_ary=( "${!arg_hsh[@]}" ) ;;
    *       ) local -a var_ary=( "$1"             ) ;;
  esac
  local statement
  local var

  (( ${#var_ary[@]} )) || return 0
  for var in "${var_ary[@]}"; do
    is_set arg_hsh["$var"] && \
      printf -v statement '%sdeclare %s=%q\n'                   "${statement:-}" "$var"         "${arg_hsh[$var]:-}" || \
      printf -v statement '%s$(in_scope %s) || declare %s=%q\n' "${statement:-}" "$var" "$var"  "${arg_hsh[$var]:-}"
  done
  emit "$statement"
}

in_scope () {
  get_here_str <<'  EOS'
    is_set %s                         && \
      {
        (( ! ${#FUNCNAME[@]} ))       || \
          (
            declare -g %s=$'sigil\037'
            [[ $%s != $'sigil\037' ]] && \
              {
                unset -v %s
                ! is_set %s
              }
          )
      }
  EOS
  printf -v __ "$__" "$1" "$1" "$1" "$1" "$1"
  emit "$__"
}

instantiate   () { printf -v "$1" %s "$(eval "echo ${!1}")" ;}
is_feature    () { is_set __features["$1"]                  ;}
is_identifier () { [[ $1 =~ ^[_[:alpha:]][_[:alnum:]]*$ ]]  ;}
is_literal    () { [[ $1 == '('*')' ]] ;}

is_set () {
  set -- "$1" "${1%%[*}"
  declare -p "$2" >/dev/null 2>&1 || return
  [[ -n ${!1+x} ]]
}

feature () {
  local feature_name=$1; shift
  local depth=1
  (( $# )) && $(grab depth from "$@")
  local i
  local path=''
  local statement

  get_here_str <<'  EOS'
    (
      declare -A ns_hsh=${__ns:-}
      declare -A features_hsh=${ns_hsh[features]:-}
      [[ -n ${features_hsh[%s]:-} && ${1:-} != 'reload' ]]
    ) && return
    __ns=$(
      declare -A ns_hsh=${__ns:-}
      type -P greadlink >/dev/null 2>&1 && readlink='greadlink -f --' || readlink='readlink -f --'
      %s="( [root]=\\"$($readlink "$(dirname "$($readlink "$BASH_SOURCE")")"%s)\\" )"
      [[ -z ${ns_hsh[features]:-} ]] && ns_hsh[features]='()'
      stuff %s into ns_hsh[features]
      ns_hsh[features]=$__
      repr ns_hsh
      echo "$__"
    )
    [[ ${1:-} == 'reload' ]] && shift
  EOS
  statement=$__
  (( depth )) && for (( i = 0; i < depth; i++ )); do path+=/..; done
  printf -v statement "$statement" "$feature_name" "$feature_name" "$path" "$feature_name"
  emit "$statement"
}

load () { require "$1" reload ;}

local_ary () {
  local first=$1; shift
  local name
  local value

  name=${first%%=*}
  (( $# )) && value="${first#*=} $*" || value=${first#*=}
  is_literal "$value" && emit "eval 'declare -a $name=$value'" || emit 'eval "declare -a '"$name"'=${'"$value"'}"'
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
  case $# in
    1 )
      is_set "$value" && value=${!value}
      shift
      ;;
    * ) is_literal "$*" && { value=$*; set -- ;};;
  esac
  { [[ -z $value ]] || is_literal "$value" ;} && {
    ! (( $# )) || return
    emit "eval 'declare -A $name=$value'"
    return
  }
  for item in "$value" "$@"; do
    [[ $item == *?=* ]] || return
    printf -v result '%s [%s]=%q' "$result" "${item%%=*}" "${item#*=}"
  done
  emit "eval 'declare -A $name=($result )'"
}

log () { put "$@" ;}

parse_options () {
  $(local_ary input_ary=$1); shift
  local -A option_hsh=()
  local -A result_hsh=()
  local arg_ary=()
  local input
  local name
  local option
  local statement

  for input in "${input_ary[@]}"; do
    $(assign input to '( short long argument help )')
    short=${short#-}
    long=${long#--}
    long=${long//-/_}
    [[ -n $long ]] && name=$long || name=$short
    stuff '( argument name help )' into '()'
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
    [[ $1 =~ ^-{1,2}[^-] && -n ${option_hsh[$option]:-} ]] && {
      $(grab '( argument name )' from "${option_hsh[$option]}")
      case $argument in
        ''  ) result_hsh[flag_$name]=1         ;;
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
  [[ $2 == 'on' ]] || return
  local IFS=$3
  local result_ary=()

  result_ary=( $1 )
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
  __=$(declare -p "$1" 2>/dev/null) || return
  [[ ${__:9:1} == [aA] ]] && {
    __=${__#*=}
    __=${__#\'}
    __=${__%\'}
    __=${__//\'\\\'\'/\'}
    return
  }
  __=${__#*=}
  __=${__#\"}
  __=${__%\"}
}

require () {
  local spec=$1; shift
  local reload=${1:-}
  local IFS=$IFS
  local extension
  local extension_ary=()
  local item
  local file
  local path

  [[ $reload == 'reload' ]] && extension_ary=( '' ) || extension_ary=( .bash .sh '' )
  [[ $spec == /* ]] && { path=${spec%/*}; spec=${spec##*/} ;} || path=$PATH
  IFS=:
  for item in $path; do
    for extension in "${extension_ary[@]}"; do
      [[ -e $item/$spec$extension ]] && break 2
    done
  done
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

  $(with __macros)

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
  get_str <<'  EOS'
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
  [[ $2 == 'into' ]]  || return
  is_literal "$1"     && eval "local -a ref_ary=$1" || local -a ref_ary=( "$1" )
  $(local_hsh result_hsh=$3)
  local ref

  for ref in "${ref_ary[@]}"; do
    result_hsh[$ref]=${!ref}
  done
  repr result_hsh
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
