[[ -n ${__featureh[concorde]:-} && ${1:-} != 'reload' ]] && return
[[ ${1:-} == 'reload' ]] && shift

declare -Ag __featureh
__featureh[concorde]="(
    [root]='$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/..)'
  [caller]='$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[1]}")")")'
)"

unset -v CDPATH
set -o noglob

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
  [[ $2 == 'from'   ]] || return
  [[ $1 == '('*')'  ]] && local -a function_ary=$1 || local -a function_ary=( "$1" )
  local spec=$3
  local feature

  $(require "$spec")
  feature=${spec##*/}
  feature=${feature%.*}
  $(grab dependencies from "${__featureh[$feature]}")
  [[ -n $dependencies ]] && {
    local -a dependency_ary=$dependencies
    function_ary+=( "${dependency_ary[@]}" )
  }
  repr function_ary
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

glob () { __=$(set +o noglob; eval "echo $1") ;}

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

feature () {
  local feature_name=$1
  local depth=${2:-1}
  local i
  local path
  local statement

  get_here_str <<'  EOS'
    [[ -n ${__featureh[%s]:-} && $1 != 'reload' ]] && return
    [[ ${1:-} == 'reload' ]]  && shift
    declare -Ag __featureh
    __featureh[%s]="(
        [root]='$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"%s)'
      [caller]='$(readlink -f "$(dirname "$(readlink -f "${BASH_SOURCE[1]}")")")'
    )"
  EOS
  statement=$__
  path=''
  (( depth )) && for (( i = 0; i < depth; i++ )); do path+=/..; done
  printf -v statement "$statement" "$feature_name" "$feature_name" "$path"
  emit "$statement"
}

load () { require "$1" load ;}

local_ary () {
  local first=$1; shift
  local name
  local value

  name=${first%%=*}
  (( $# )) && value="${first#*=} $*" || value=${first#*=}
  [[ $value == '('*')' ]] && emit "declare -a $name=$value" || emit 'declare -a '"$name"'=$'"$value"
}

local_hsh () {
  local first=$1; shift
  local name
  local value

  name=${first%%=*}
  (( $# )) && value="${first#*=} $*" || value=${first#*=}
  [[ $value == '('*')' ]] && emit "declare -A $name=$value" || emit 'declare -A '"$name"'=$'"$value"
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
    [[ $1 =~ ^-{1,2}[^-] && -n ${optionh[$option]:-} ]] && {
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
  case ${#args[@]} in
    '0' ) statement='set --';;
    *   )
      printf -v statement '%q ' "${args[@]}"
      printf -v statement 'set -- %s' "$statement"
      ;;
  esac
  repr resulth
  printf -v statement '%s\n__=%q' "${statement:-}" "$__"
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
  local library=$1; shift
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
  [[ $library == /* || $library != *?/* ]] || return
  [[ $library == /* ]] && { path=${library%/*}; library=${library##*/} ;}
  IFS=:
  for spec in $path; do
    for extension in "${extensions[@]}"; do
      [[ -e $spec/$library$extension ]] && break 2
    done
  done
  file=$spec/$library$extension
  [[ -e $file ]] || return
  emit "source $file $@"
}

require_relative () {
  local library=$1
  local extension
  local extensions=()
  local file

  extensions=(
    .bash
    .sh
    ''
  )
  [[ $library != /* && $library == *?/* ]] || return
  $(grab caller from __featureh[concorde])
  file=$caller/$library
  for extension in "${extensions[@]}"; do
    [[ -e $file$extension ]] && break
  done
  file=$file$extension
  [[ -e $file ]] || return
  emit "source $file"
}

sourced? () { [[ ${FUNCNAME[@]: -1} == 'source' ]] ;}

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
