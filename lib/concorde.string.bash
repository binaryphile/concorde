concorde_string_Dir=$(dirname $(readlink -f $BASH_SOURCE))
source $concorde_string_Dir/as module
module.already_loaded && return

source $concorde_string_Dir/concorde.core.bash

ascii_only?  () {
  [[ ${1:-} != *[^[:ascii:]]* ]]
}

blank? () {
  local item=${1:-}

  [[ -z ${item//[[:space:]]} ]]
}

capitalize () {
  local -n ref_=$2

  ref_=${1,,}
  ref_=${ref_^}
}

center () {
  local length_=${#1}
  local width_=$2
  local -n ref_=$3
  local padstr_=${4:- }
  local -i num_
  local pad_

  num_="(width_ - length_)/(2*${#padstr_})"
  times $padstr_ $num_ pad_
  num_="num_ % ${#padstr_}"
  pad_+=${padstr_:0:num_-1}
  ref_=$pad_$1
  num_="(width_ - (${#pad_} + length_))/${#padstr_}"
  times $padstr_ $num_ pad_
  num_="num_ % ${#padstr_}"
  pad_+=${padstr_:0:num_}
  ref_+=$pad_
}

chars () {
  local -n ref_=$2
  local i_

  for (( i_ = 0; i_ < ${#1}; i_++ )); do
    ref_+=( ${1:i_:1} )
  done
}

chomp () {
  case $# in
    2 )
      local -n ref_=$2

      case $1 in
        *$'\r\n'      ) ref_=${1%$'\r\n'} ;;
        *$'\r'|*$'\n' ) ref_=${1%?}       ;;
        *             ) ref_=$1           ;;
      esac
      ;;
    3 )
      local -n ref_=$3

      ref_=$1
      case $2 in
        '' )
          while [[ $ref_ == *$'\r\n' ]]; do
            ref_=${ref_%$'\r\n'}
          done;:
          ;;
        * ) ref_=${1%$2}
      esac
      ;;
  esac
}

chop () {
  local -n ref_=$2

  case $1 in
    *$'\r\n'  ) ref_=${1%$'\r\n'} ;;
    *         ) ref_=${1%?}       ;;
  esac
}

chr () {
  local -n ref_=$2

  ref_=${1:0:1}
}

codepoints () {
  local i_

  for (( i_ = 0; i_ < ${#1}; i_++ )); do
    printf -v $2[i_] %d "'${1:i_:1}"
  done
}

compare () {
  local -n ref_=$3

  [[ $1 < $2    ]] && ref_=-1
  [[ $1 == "$2" ]] && ref_=0
  [[ $1 > $2    ]] && ref_=1;:
}

count () {
  local -n ref_=${!#}
  local target_=$1
  set -- ${*:2:$#-2}
  local spec_
  local result_

  for spec_; do
    for (( i_ = 0; i_ < ${#target_}; i_++ )); do
      [[ ${target_:i_:1} == [$spec_] ]] && result_+=${target_:i_:1}
    done
    target_=$result_
    result_=''
  done
  ref_=${#target_}
}

delete () {
  local -n ref_=${!#}
  local target_=$1
  local copy_=$1
  set -- ${*:2:$#-2}
  local result_
  local spec_

  for spec_; do
    for (( i_ = 0; i_ < ${#target_}; i_++ )); do
      [[ ${target_:i_:1} == [$spec_] ]] && result_+=${target_:i_:1}
    done
    target_=$result_
    result_=''
  done

  target_=${target_//^/\^}
  target_=${target_//-/\-}
  for (( i_ = 0; i_ < ${#copy_}; i_++ )); do
    [[ ${copy_:i_:1} != [$target_] ]] && ref_+=${copy_:i_:1};:
  done
}

downcase () {
  local -n ref_=$2

  ref_=${1,,}
}

dump () {
  printf -v $2 %q "$1"
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

eq? () {
  [[ $1 == "$2" ]]
}

ge? () {
  [[ $1 > $2 || $1 == "$2" ]]
}

getbyte () {
  printf -v $3 %d \'${1:$2:1}
}

gsub () {
  local -n ref_=$4

  ref_=${1//$2/$3}
}

gt? () {
  [[ $1 > $2 ]]
}

include? () {
  [[ $1 == *"$2"* ]]
}

hex () {
  [[ $1 == *[^+\-[:digit:]a-fx]* ]] && {
    printf -v $2 %s 0
    return
  }
  case $1 in
    0x*|0X* ) printf -v $2 %d $1        ;;
    -*      ) printf -v $2 %d -0x${1#-} ;;
    *       ) printf -v $2 %d 0x$1      ;;
  esac
}

index () {
  local target_=$1; shift
  local search_=$1; shift
  local -n ref_=$1; shift
  local i_
  local offset=0
  kwargs $*

  ref_=''
  for (( i_ = $offset; i_ < ${#target_} - ${#search_} + 1; i_++ )); do
    eq? ${target_:i_:${#search_}} $search_ && {
      ref_=$i_
      return
    };:
  done
}

insert () {
  case $2 in
    -1  ) printf -v $4 %s ${1:0:$#+$2+1}$3          ;;
    -*  ) printf -v $4 %s ${1:0:$#+$2+1}$3${1:$2+1} ;;
    *   ) printf -v $4 %s ${1:0:$2}$3${1:$2}        ;;
  esac
}

inspect () {
  printf -v $2 %q $1
  [[ ${!2} == \$\'*\' ]] && return
  printf -v $2 '"%s"' ${!2}
}

le? () {
  [[ $1 < $2 || $1 == "$2" ]]
}

left () {
  printf -v $3 %s ${1:0:$2}
}

length () {
  printf -v $2 %s ${#1}
}

lines () {
  local -n ref_=${!#}
  local IFS=$IFS

  (( $# == 3 )) && IFS=$2
  ref_=( $1 )
}

ljust () {
  local -n ref_=${!#}
  set -- ${*:1:$#-1}
  local padstr_=${3:- }
  local -i mod_
  local -i num_

  num_=($2-${#1})/${#padstr_}
  mod_=mod_%${#padstr_}
  times $padstr_ $num_ pad_
  ref_=$1$pad_${padstr_:0:mod_-1}
}

lower () {
  printf -v $2 %s ${1,,}
}

lstrip () {
  local -n ref_=$2

  ref_=${1%%[^[:space:]]*}
  ref_=${1#$ref_}
}

lt? () {
  [[ $1 < $2 ]]
}

next () {
  local -n ref_=$2
  local -i ord_
  local IFS=$IFS
  local chr_
  local i_
  local results_=()

  carry_=1
  for (( i_ = ${#1}; i_ > 0; i_-- )); do
    chr_=${1:i_-1:1}
    ! (( carry_ )) && {
      results_[i_]=$chr_
      continue
    }
    printf -v ord_ %d \'$chr_
    ord_+=1
    printf -v ord_ %02o $ord_
    case $chr_ in
      [a-y]|[A-Y]|[0-8] ) printf -v results_[i_] %b \\$ord_; carry_=0   ;;
      z|Z               ) printf -v results_[i_] %b \\$(( ord_ - 32 ))  ;;
      9                 ) results_[i_]=0                                ;;
      *                 ) results_[i_]=$chr_                            ;;
    esac
  done
  (( carry_ )) && case $chr_ in
    z|Z ) printf -v results_[0] %b \\$(( ord_ - 32 )) ;;
    9   ) results_[0]=1                               ;;
  esac
  IFS=''
  ref_=${results_[*]}
}

partition () {
  local -n ref_=$3

  ref_=( ${1%%$2*} $2 ${1#*$2} )
}

present? () {
  local item=${1:-}

  [[ -n ${item//[[:space:]]} ]]
}

reverse () {
  local -n ref_=$2
  local i_

  for (( i_ = ${#1} - 1; i_ >= 0; i_-- )); do
    ref_+=${1:i_:1}
  done
}

right () {
  local -n ref_=$3

  ref_=${1:${#1}-$2:${#1}}
}

rindex () {
  local target_=$1; shift
  local search_=$1; shift
  local -n ref_=$1; shift
  local i_
  local -i offset=${#target_}
  kwargs $*

  ref_=''
  for (( i_ = $offset - ${#search_}; i_ >= 0; i_-- )); do
    eq? ${target_:i_:${#search_}} $search_ && {
      ref_=$i_
      return
    };:
  done
}

rpartition () {
  local -n ref_=$3

  ref_=( ${1%$2*} $2 ${1##*$2} )
}

rstrip () {
  local -n ref_=$2

  ref_=${1##*[^[:space:]]}
  ref_=${1%$ref_}
}

split () {
  local -n ref_=$3
  local delim_=${2:-[[:space:]]}

  while [[ $1 != ${1/$delim_} ]]; do
    ref_+=( ${1%%$delim_*} )
    set -- "${1#*$delim_}"
  done
  ref_+=( $1 )
}

strip () {
  local tmp

  lstrip $1 tmp
  rstrip $tmp $2
}

substr () {
  local -n ref_=$4

  ref_=${1:$2:$3-$2}
}

times () {
  local -n ref_=$3
  local i_

  ref_=''
  for (( i_ = 0; i_ < $2; i_++ )); do
    ref_+=$1
  done
}

upcase () {
  local -n ref_=$2

  ref_=${1^^}
}

upper () {
  local -n ref_=$2

  ref_=${1^^}
}
