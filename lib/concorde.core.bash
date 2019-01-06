shopt -s expand_aliases
alias args?='(( $# ))'
alias kwargs='(( $# )) && declare'

alias_retvar () {
  alias "$1=declare \$$1 && retvar_ \$$1"
}

retvar_ () {
  return_ $1 ${*:3}
}

alias_var () {
  local item

  for item; do
    alias "$item=var_ $item"
  done
}

array () {
  local item_
  local name_
  local ref_
  local result_
  local results_=()

  for item_; do
    name_=${item_%=*}
    ref_=${item_#*=}
    [[ -z $ref_ ]] && {
      results_+=( "$name_=()" )
      continue
    }
    result_=$(declare -p $ref_)
    result_=${result_/$ref_/$name_}
    results_+=( $result_ )
  done
  emit <<<"${results_[*]}"
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

directory? () {
  [[ -d $1 ]]
}

downcase () {
  printf -v $1 %s ${2,,}
}

dump () {
  printf -v $1 %q "$2"
}

emit () {
  local code_

  IFS='' read -rd '' code_
  printf ${1:+-v$IFS$1} eval%seval%s%q "$IFS" "$IFS" "$code_"
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

executable? () {
  [[ -x $1 ]]
}

file? () {
  [[ -f $1 ]]
}

get () {
  local -n heredoc_=$1
  local indent_

  get_heredoc heredoc_
  indent_=${heredoc_%%[^[:space:]]*}
  heredoc_=${heredoc_#$indent_}
  heredoc_=${heredoc_//$'\n'$indent_/$'\n'}
}

get_heredoc () {
  ! IFS=$'\n' read -rd '' $1
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

  ! (( $# > 2 ))
  case $? in
    0 ) result_=$(declare -p $2);;
    * )
      $2 result_ ${*:3}
      result_=$(declare -p result_)
      ;;
  esac
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
