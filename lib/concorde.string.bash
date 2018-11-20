concorde_string_Dir=$(dirname $(readlink -f $BASH_SOURCE))
source $concorde_string_Dir/as module
module.already_loaded && return

source $concorde_string_Dir/concorde.core.bash

* () {
  local -n ref_=$3
  local i_

  ref_=''
  for (( i_ = 0; i_ < $2; i_++ )); do
    ref_+=$1
  done
}

blank? () {
  [[ -z ${1:-} ]]
}

compare () {
  local -n ref_=$3

  [[ $1 < $2    ]] && ref_=-1
  [[ $1 == "$2" ]] && ref_=0
  [[ $1 > $2    ]] && ref_=1;:
}

downcase () {
  local -n ref_=$2

  ref_=${1,,}
}

eq? () {
  [[ $1 == "$2" ]]
}

ge? () {
  [[ $1 > $2 || $1 == "$2" ]]
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

le? () {
  [[ $1 < $2 || $1 == "$2" ]]
}

left () {
  local -n ref_=$3

  ref_=${1:0:$2}
}

length () {
  local -n ref_=$2

  ref_=${#1}
}

lower () {
  local -n ref_=$2

  ref_=${1,,}
}

lstrip () {
  local -n ref_=$2

  ref_=${1%%[^[:space:]]*}
  ref_=${1#$ref_}
}

lt? () {
  [[ $1 < $2 ]]
}

partition () {
  local -n ref_=$3

  ref_=( ${1%%$2*} $2 ${1#*$2} )
}

present? () {
  [[ -n ${1:-} ]]
}

replace () {
  local -n ref_=$4

  ref_=${1//$2/$3}
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

upcase () {
  local -n ref_=$2

  ref_=${1^^}
}

upper () {
  local -n ref_=$2

  ref_=${1^^}
}
