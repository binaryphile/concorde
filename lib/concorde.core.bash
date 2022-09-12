shopt -s expand_aliases
alias args?='(( $# ))'
alias kwargs='(( $# )) && declare'

alias_retvar () {
  local item statement

  for item; do
    ! [[ $item == *,* ]]
    case $? in
      0 ) alias $item="declare \$$item && _retvar_ $item"             ;;
      * ) eval "alias $item=\"declare \\\${$item} && _retvar_ $item\"";;
    esac
  done
}

alias_var () {
  local item

  for item; do
    alias "$item=_var_ $item"
  done
}

alias_var item getopts,names,flags
alias_retvar g,n,f p,o result results

array () {
  local item_ name_ ref_ results_=()

  for item_; do
    name_=${item_%=*}
    ref_=${item_#*=}
    [[ -z $ref_ ]] && {
      results_+=( "$name_=()" )
      continue
    }
    item_=$(declare -p $ref_)
    item_=${item_/$ref_/$name_}
    results_+=( $item_ )
  done
  emit "${results_[*]}"
}

blank? () {
  local item=${1:-}

  [[ -z ${item//[[:space:]]} ]]
}

capitalize () {
  local result=$1 item

  item=${2,,}
  item=${item^}
  result = item
}

_denormopts_ () {
  local g=$1 n=$2 f=$3 IFS=$IFS defn long='' opt short=''
  local -A getopts=() names=() flags=()

  getopts[long]=''
  getopts[short]=''
  for defn in $4; do
    IFS=,
    set -- $defn
    IFS='|'
    for opt in $1; do
      names[$opt]=$2
      case $opt in
        -?  ) short+=,${opt#?};;
        *   ) long+=,${opt#??};;
      esac
      case ${3:-} in
        '' )
          case $opt in
            -?  ) short+=: ;;
            *   ) long+=:  ;;
          esac
          ;;
        * ) flags[$opt]=1;;
      esac
    done
  done
  getopts[long]=${long#?}
  getopts[short]=${short#?}
  g,n,f = getopts,names,flags
}

die () {
  local rc=$? msg=${1:-}

  [[ -z $msg ]] && exit $rc
  case $rc in
    0 ) echo "$msg"     ;;
    * ) echo "$msg" >&2 ;;
  esac
  exit $rc
}

directory? () {
  [[ -d $1 ]]
}

downcase () {
  printf -v $1 %s "${2,,}"
}

dump () {
  printf -v $1 %q "$2"
}

emit () {
  printf eval"$IFS"eval"$IFS"%q "$1"
}

empty? () {
  [[ -z ${1:-} ]]
}

end_with? () {
  local target=$1 item
  shift

  for item; do
    [[ $target == *"$item" ]] && return
  done
  return 1
}

_enhanced_getopt?_ () {
  local rc

  getopt -T &>/dev/null && rc=$? || rc=$?
  (( rc == 4 ))
}

executable? () {
  [[ -x $1 ]]
}

file? () {
  [[ -f $1 ]]
}

get () {
  local result=$1 indent item

  item = get_heredoc
  indent=${item%%[^[:space:]]*}
  item=${item#$indent}
  item=${item//$'\n'$indent/$'\n'}
  result = item
}

get_heredoc () {
  ! IFS=$'\n' read -rd '' $1
}

gsub () {
  printf -v $1 %s "${2//$3/$4}"
}

include? () {
  [[ $1 == *"$2"* ]]
}

join () {
  $(array items=$2)
  local result=$1 item joined=''

  for item in ${items[*]}; do
    joined+=$item$3
  done
  joined=${joined%$3}
  result = joined
}

left () {
  printf -v $1 %s "${2:0:$3}"
}

length () {
  printf -v $1 %s ${#2}
}

lines () {
  local results=$1 IFS=$IFS lines=()

  (( $# == 3 )) && IFS=$3
  lines=( $2 )
  results = lines
}

parseopts () {
  local p=$1 o=$2 def_list=$3 posargs=() opts=()
  local -A flags=() getopts=() names=()
  local -i i=0

  _err_=0
  getopts,names,flags = _denormopts_ "$def_list"

  _enhanced_getopt?_ && eval $(_wrap_getopt_ "$def_list" "${getopts[short]}" "${getopts[long]}")

  while [[ ${1:-} == -?* ]]; do
    [[ $1 == -- ]] && {
      shift
      break
    }
    defined? names[$1] || {
      _err_=1
      return
    }
    ! defined? flags[$1]
    case $? in
      0 )
        opts[i]=${names[$1]}=$2
        shift
        ;;
      * ) opts[i]=${names[$1]}=1;;
    esac
    shift
    i+=1
  done
  for (( i = 1; i <= $#; i++ )); do
    posargs[i-1]=${!i}
  done
  p,o = posargs,opts
}

present? () {
  local item=${1:-}

  [[ -n ${item//[[:space:]]} ]]
}

_return_ () {
  local item_ names_=() value_ values_=()

  for item_; do
    names_+=( ${item_%%=*} )
    value_=$(declare -p ${item_#*=})
    value_=${value_#*=}
    value_=${value_#\'}
    values_+=( "${value_%\'}" )
  done
  unset -v ${names_[*]}
  for (( i_ = 0; i_ < ${#names_[*]}; i_++ )); do
    eval "${names_[i_]}=${values_[i_]}"
  done
}

_retvar_ () {
  local oldIFS_=$IFS IFS=, i_ names_=() values_=()

  (( $# > 3 )) && {
    unset -v ${!1}
    IFS=$oldIFS_
    $3 ${!1} "${@:4}"
    return
  }
  names_=( $1 )
  values_=( $3 )
  for (( i_ = 0; i_ < ${#names_[*]}; i_++ )); do
    values_[i_]=${!names_[i_]}=${values_[i_]}
  done
  _return_ ${values_[*]}
}

reverse () {
  local result=$1 i reverse=''

  for (( i = ${#2} - 1; i >= 0; i-- )); do
    reverse+=${2:i:1}
  done
  result = reverse
}

right () {
  printf -v $1 %s "${2:${#2}-$3:${#2}}"
}

slice () {
  printf -v $1 %s "${2:$3:${4:-1}}"
}

sourced? () {
  [[ ${FUNCNAME[1]} == source ]]
}

strict_mode () {
  case $1 in
    on )
      set -o errexit
      set -o nounset
      set -o pipefail
      ;;
    off )
      set +o errexit
      set +o nounset
      set +o pipefail
      ;;
  esac
}

substr () {
  printf -v $1 %s "${2:$3:$4-$3}"
}

upcase () {
  printf -v $1 "${2^^}"
}

_var_ () {
  [[ $3 == printf ]] && {
    printf -v $1 "${@:3}"
    return
  }
  case $(type -t $3) in
    function  ) $3 $1 "${@:4}"              ;;
    *         ) printf -v $1 %s "$(${*:3})" ;;
  esac
}

_wrap_getopt_ () {
  local short=$2
  local long=$3
  local result

  ! result=$(getopt -o "$short" ${long:+-l} $long -n $0 -- $1)
  case $? in
    0 ) echo '_err_=1; return';;
    * ) echo "set -- $result" ;;
  esac
}

unalias item result results
