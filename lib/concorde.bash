[[ -n ${__conco:-} && -z ${reload:-}  ]] && return
[[ -n ${reload:-}                     ]] && { unset -v reload && echo reloaded || return ;}
[[ -z ${__conco:-}                    ]] && readonly __conco=loaded
CONCO_ROOT=$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/..)
CONCO_SRCE=$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[1]}")")")

unset -v CDPATH

assign () {
  [[ $2 == 'to'     ]] || return
  [[ $3 == '('*')'  ]] && local -a vars=$3 || local -a vars=( "$3" )
  $(local_ary args="$1")
  local var
  local statement

  set -- "${args[@]}"
  for var in "${vars[@]}"; do
    printf -v statement '%sdeclare %s=%q\n' "${statement:-}" "$var" "$1"
    shift
  done
  emit "$statement"
}

bring () { (
  [[ $2 == 'from'   ]] || return
  [[ $1 == '('*')'  ]] && local -a functions=$1 || local -a functions=( "$1" )
  local library=$3

  $(require "$library")
  (( ${#__dependencies[@]:-} )) && functions+=( "${__dependencies[@]}" )
  repr functions
  _extract_functions __
  emit "$__"
) }

die () { [[ -n $1 ]] && puterr "$1"; exit "${2:-1}" ;}

emit () { printf 'eval eval %q\n' "$1" ;}

_extract_function () {
  local function=$1
  local IFS=$'\n'

  set -- $(type "$function")
  shift
  printf -v __ '%s\n' "$@"
}

_extract_functions () {
  [[ $1 == '('*')' ]] && local -a functions=$1 || local -a functions=${!1}
  local function
  local result

  for function in "${functions[@]}"; do
    _extract_function "$function"
    result+=$__
  done
  repr result
}

get_ary () {
  local results=()

  IFS=$'\n' read -rd '' -a results ||:
  repr results
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

get_str () { IFS=$'\n' read -rd '' __ ||: ;}

grab () {
  [[ $2 == 'from'   ]] || return
  [[ $3 == '('*')'  ]] && local -A argh=$3 || local -A argh=${!3}
  case $1 in
    '('*')' ) local -a vars=$1                ;;
    '*'     ) local -a vars=( "${!argh[@]}" ) ;;
    *       ) local -a vars=(          "$1" ) ;;
  esac
  local var
  local statement

  for var in "${vars[@]}"; do
    printf -v statement '%sdeclare %s=%q\n' "${statement:-}" "$var" "${argh[$var]:-}"
  done
  emit "$statement"
}

instantiate () { printf -v "$1" %s "$(eval "echo ${!1}")" ;}

library () {
  local library_name=$1
  local depth=${2:-1}
  local i
  local path
  local statement

  get_here_str <<'  EOS'
    [[ -n ${__%s:-} && -z ${reload:-} ]] && return
    [[ -n ${reload:-}                 ]] && { unset -v reload && echo reloaded || return ;}
    [[ -z ${__%s:-}                   ]] && readonly __%s=loaded
    %s_ROOT=$(readlink -f "$(dirname "$(readlink -f "$BASH_SOURCE")")"%s)
  EOS
  statement=$__
  path=''
  (( depth )) && for (( i = 0; i < depth; i++ )); do path+=/..; done
  printf -v statement "$statement" "$library_name" "$library_name" "$library_name" "${library_name^^}" "$path"
  emit "$statement"
}

local_ary () {
  local name=${1%%=*}
  local value=${1#*=}
  [[ $value == '('*')' ]] && emit "declare -a $name=$value" || emit 'declare -a '"$name"'=$'"$value"
}

local_hsh () {
  local name=${1%%=*}
  local value=${1#*=}
  [[ $value == '('*')' ]] && emit "declare -A $name=$value" || emit 'declare -A '"$name"'=$'"$value"
}

local_str () {
  local name=${1%%=*}
  local value=${1#*=}
  [[ $value == '('*')' ]] && emit "declare -- $name=$value" || emit 'declare -- '"$name"'=$'"$value"
}

log () { put "$@" ;}

parse_options () {
  [[ $1 == '('*')' ]] && local -a inputs=$1 || local -a inputs=${!1}; shift
  local -A optionh=()
  local -A resulth=()
  local args=()
  local input
  local name
  local option
  local statement

  for input in "${inputs[@]}"; do
    $(assign input to '( short long argument help )')
    short=${short#-}
    long=${long#--}
    long=${long//-/_}
    [[ -n $long ]] && name=$long || name=$short
    stuff '( argument name help )' into '()'
    [[ -n $short  ]] && optionh[$short]=$__
    [[ -n $long   ]] && optionh[$long]=$__
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
    { [[ $1 =~ ^-{1,2}[^-] ]] && [[ -n ${optionh[$option]:-} ]] ;} && {
      $(grab '( argument name )' from "${optionh[$option]}")
      case $argument in
        ''  ) resulth[flag_$name]=1         ;;
        *   ) resulth[$argument]=$2; shift  ;;
      esac
      shift
      continue
    }
    case $1 in
      '--'  ) shift                           ; args+=( "$@" ); break ;;
      -*    ) puterr "unsupported option $1"  ; return 1              ;;
      *     ) args+=( "$@" )                  ; break                 ;;
    esac
    shift
  done
  statement="set -- ${args[@]}"
  repr resulth
  printf -v statement '%s\n__=%s' "$statement" "$__"
  emit "$statement"
}

part () {
  [[ $2 == 'on' ]] || return
  local IFS=$3
  local results=()

  results=( $1 )
  repr results
}

put     () { printf '%s\n' "$@"   ;}
puterr  () { put "Error: $1" >&2  ;}

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
  local library=$1
  local IFS=$IFS
  local extension
  local extensions=()
  local file
  local path
  local spec

  extensions=(
    .bash
    .sh
    ''
  )
  [[ $library == */*  ]] && path=${library%/*} || path=.:$PATH
  library=${library##*/}
  IFS=:
  for spec in $path; do
    for extension in "${extensions[@]}"; do
      [[ -e $spec/$library$extension ]] && break 2
    done
  done
  file=$spec/$library$extension
  [[ -e $file ]] || return
  emit "source $file"
}

require_relative () {
  local library=$1
  local extension
  local extensions=()
  local file
  local spec

  extensions=(
    .bash
    .sh
    ''
  )
  [[ $library == */*  ]] || return
  file=$CONCO_SRCE/$library
  for extension in "${extensions[@]}"; do
    [[ -e $file$extension ]] && break
  done
  file=$file$extension
  [[ -e $file ]] || return
  emit "source $file"
}

return_if_sourced () { emit 'return 0 2>/dev/null ||:' ;}

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
  [[ $2 == 'into'   ]] || return
  [[ $1 == '('*')'  ]] && local -a refs=$1    || local -a refs=( "$1" )
  [[ $3 == '('*')'  ]] && local -A resulth=$3 || local -A resulth=${!3}
  local ref

  for ref in "${refs[@]}"; do
    resulth[$ref]=${!ref}
  done
  repr resulth
}

traceback () {
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
  [[ $2 == 'with'   ]] || return
  [[ $1 == '('*')'  ]] && local -A hash=$1     || local -A hash=${!1}
  [[ $3 == '('*')'  ]] && local -A updateh=$3  || local -A updateh=${!3}
  local key

  for key in "${!updateh[@]}"; do
    hash[$key]=${updateh[$key]}
  done
  repr hash
}

wed () {
  [[ $2 == 'with' ]] || return
  [[ $1 == '('*')' ]] && local -a ary=$1 || local -a ary=${!1}
  local IFS=$3

  __=${ary[*]}
}

with () { repr "$1"; grab '*' from "$__" ;}
