[[ -n ${__idiom:-} && -z ${reload:-}  ]] && return
[[ -n ${reload:-}                 ]] && { unset -v reload && echo reloaded || return ;}
[[ -z ${_%s:-}                    ]] && readonly _%s=loaded
%s_ROOT=$(readlink -f "$(dirname "$(readlink -f "$BASH_SOURCE")")"%s)

assign () {
  [[ $2 == 'to'     ]] || return
  [[ $1 == '('*')'  ]] && local -a args=$1 || local -a args=${!1}
  [[ $3 == '('*')'  ]] && local -a vars=$3 || local -a vars=( "$3" )
  local var
  local statement

  set -- "${args[@]}"
  for var in "${vars[@]}"; do
    printf -v statement '%sdeclare %s=%q\n' "$statement" "$var" "$1"
    shift
  done
  expose "$statement"
}

bring () { (
  [[ $2 == 'from'   ]] || return
  [[ $1 == '('*')'  ]] && local -a functions=$1 || local -a functions=${!1}
  local library=$3

  require library
  [[ -n ${required_imports[@]:-} ]] && functions+=( "${_required_imports[@]}" )
  inspect functions
  _echo_functions __
) }

die () { [[ -n $1 ]] && puterr "$1"; exit "${2:-1}" ;}

_echo_function () {
  local function=$1
  local IFS=$'\n'

  set -- $(type function)
  shift
  printf '%s\n' "$*"
}

_echo_functions () {
  [[ $1 == '('*')' ]] && local -a functions=$1 || local -a functions=${!1}
  local function

  for function in "${functions[@]}"; do
    _echo_function "$function"
  done
}

expose () { printf 'eval eval %q\n' "$1" ;}

inspect () {
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

get_ary () {
  local results=()

  IFS=$'\n' read -rd '' -a results ||:
  inspect results
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
    printf -v statement '%sdeclare %s=%q\n' "$statement" "$var" "${argh[$var]}"
  done
  expose "$statement"
}

instantiate () { printf -v "$1" %s "$(eval "echo ${!1}")" ;}

module () {
  local module_name=$1
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
  printf -v statement "$statement" "$module_name" "$module_name" "$module_name" "${module_name^^}" "$path"
  expose "$statement"
}

options_new () {
  [[ $1 == '('*')' ]] && local -a inputs=$1 || local -a inputs=${!1}
  declare -p __instanceh >/dev/null 2>&1    || declare -Ag __instanceh=( [next_id]=0 )
  local -A optionh=()
  local input
  local name
  local next_id

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

  next_id=${__instanceh[next_id]}
  [[ -z ${__instanceh[$next_id]:-} ]] || return
  inspect optionh
  __instanceh[$next_id]=$__
  __=__instanceh["$next_id"]
  __instanceh[next_id]=$(( next_id++ ))
}

options_parse () {
  local -A optionh=${!1}; shift
  local -A resulth=()
  local args=()
  local option

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
  inspect args
  resulth[arg]=$__
  inspect resulth
}

part () {
  [[ $2 == 'on' ]] || return
  local IFS=$3
  local results=()

  results=( $1 )
  inspect results
}

put     () { printf '%s\n' "$@"   ;}
puterr  () { put "Error: $1" >&2  ;}
return_if_sourced () { expose 'return 0 2>/dev/null ||:' ;}

require () {
  local library=$1
  local IFS=$IFS
  local extension
  local extensions=()
  local file
  local path

  extensions=( .bash .sh '' )
  if [[ $library == */* ]]; then
    for extension in "${extensions[@]}"; do
      [[ -e $library$extension ]] && break
    done
    file=$library$extension
  else
    [[ -n ${PATH:-} ]] || return
    IFS=:
    for path in $PATH; do
      for extension in "${extensions[@]}"; do
        [[ -e $path/$library$extension ]] && break 2
      done
    done
    file=$path/$library$extension
  fi
  [[ -e $file ]] || return
  source "$file"
}

strict_mode () {
  local status=$1
  local IFS=$IFS
  local callback
  local option
  local statement

  get_here_str <<'  EOS'
    set %so errexit
    set %so errtrace
    set %so nounset
    set %so pipefail

    trap %s ERR
  EOS
  statement=$__
  case $status in
    'on'  ) option=-; callback=traceback  ;;
    'off' ) option=+; callback=-          ;;
    *     ) return 1                      ;;
  esac
  printf -v statement "$statement" "$option" "$option" "$option" "$option" "$callback"
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
  inspect resulth
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
  inspect hash
}

wed () {
  [[ $2 == 'with' ]] || return
  [[ $1 == '('*')' ]] && local -a ary=$1 || local -a ary=${!1}
  local IFS=$3

  __=${ary[*]}
}

with () { inspect "$1"; grab '*' from "$__" ;}
