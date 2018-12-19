concorde_core_Dir=$(dirname $(readlink -f $BASH_SOURCE))

shopt -s expand_aliases
alias kwargs='(( $# )) && declare'

alias_var () {
  local item

  for item; do
    eval "alias $item='var_ $item'"
  done
}

array () {
  local item_
  local result_
  local results_=()

  for item_; do
    result_=$(declare -p ${item_#*=})
    result_=${result_#*=\'}
    results_+=( ${item_%=*}=${result_%\'} )
  done
  echo "${results_[*]}"
}

blank? () {
  local item=${1:-}

  [[ -z ${item//[[:space:]]} ]]
}

capitalize () {
  local -n ref_=$1

  ref_=${2,,}
  ref_=${ref_^}
}

downcase () {
  printf -v $1 %s ${2,,}
}

dump () {
  printf -v $1 %q "$2"
}

empty? () {
  [[ -z ${1:-} ]]
}

end_with? () {
  local target=$1; shift
  local item

  for item; do
    [[ $target == *"$item" ]] && return
  done
  return 1
}

gsub () {
  printf -v $1 %s ${2//$3/$4}
}

include? () {
  [[ $1 == *"$2"* ]]
}

left () {
  printf -v $1 %s ${2:0:$3}
}

length () {
  printf -v $1 %s ${#2}
}

lines () {
  local -n ref_=$1
  local IFS=$IFS

  (( $# == 3 )) && IFS=$3
  ref_=( $2 )
}

present? () {
  local item=${1:-}

  [[ -n ${item//[[:space:]]} ]]
}

return_ () {
  local result_

  result_=$(declare -p $2)
  result_=${result_#*=}
  result_=${result_#\'}
  unset -v $1
  eval $1=${result_%\'}
}

reverse () {
  local -n ref_=$1
  local i_

  for (( i_ = ${#2} - 1; i_ >= 0; i_-- )); do
    ref_+=${2:i_:1}
  done
}

right () {
  printf -v $1 %s ${2:${#2}-$3:${#2}}
}

slice () {
  printf -v $1 %s ${2:$3:${4:-1}}
}

substr () {
  printf -v $1 %s ${2:$3:$4-$3}
}

upcase () {
  printf -v $1 ${2^^}
}

var_ () {
  [[ $3 == printf ]] && {
    printf -v $1 ${*:3}
    return
  }
  case $(type -t $3) in
    function  ) $3 $1 ${*:4}              ;;
    *         ) printf -v $1 %s $(${*:3}) ;;
  esac
}
