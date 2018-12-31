ascii_only?  () {
  [[ ${1:-} != *[^[:ascii:]]* ]]
}

center () {
  local -n ref_=$1
  local length_=${#2}
  local width_=$3
  local padstr_=${4:- }
  local -i num_
  local pad_

  num_="(width_-length_)/(2*${#padstr_})"
  times pad_ $padstr_ $num_
  num_=num_%${#padstr_}
  pad_+=${padstr_:0:num_-1}
  ref_=$pad_$2
  num_="(width_-(${#pad_}+length_))/${#padstr_}"
  times pad_ $padstr_ $num_
  num_=num_%${#padstr_}
  pad_+=${padstr_:0:num_}
  ref_+=$pad_
}

chars () {
  local -n ref_=$1
  local i_

  for (( i_ = 0; i_ < ${#2}; i_++ )); do
    ref_+=( ${2:i_:1} )
  done
}

chomp () {
  local -n ref_=$1

  case $# in
    2 )
      case $2 in
        *$'\r\n'      ) ref_=${2%$'\r\n'} ;;
        *$'\r'|*$'\n' ) ref_=${2%?}       ;;
        *             ) ref_=$2           ;;
      esac
      ;;
    3 )
      ref_=$2
      case $3 in
        '' )
          while [[ $ref_ == *$'\r\n' ]]; do
            ref_=${ref_%$'\r\n'}
          done;:
          ;;
        * ) ref_=${2%$3}
      esac
      ;;
  esac
}

chop () {
  case $2 in
    *$'\r\n'  ) printf -v $1 %s "${2%$'\r\n'}";;
    *         ) printf -v $1 %s "${2%?}"      ;;
  esac
}

chr () {
  printf -v $1 %s ${2:0:1}
}

codepoints () {
  local i_

  for (( i_ = 0; i_ < ${#1}; i_++ )); do
    printf -v $1[i_] %d "'${2:i_:1}"
  done
}

compare () {
  local -n ref_=$1

  [[ $2 < $3    ]] && ref_=-1
  [[ $2 == "$3" ]] && ref_=0
  [[ $2 > $3    ]] && ref_=1;:
}

count () {
  local -n ref_=$1
  local target_=$2
  local spec_
  local result_

  for spec_ in ${*:3:$#-2}; do
    for (( i_ = 0; i_ < ${#target_}; i_++ )); do
      [[ ${target_:i_:1} == [$spec_] ]] && result_+=${target_:i_:1}
    done
    target_=$result_
    result_=''
  done
  ref_=${#target_}
}

delete () {
  local -n ref_=$1
  local target_=$2
  local copy_=$2
  local result_
  local spec_

  for spec_ in ${*:3:$#-2}; do
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

eq? () {
  [[ $1 == "$2" ]]
}

ge? () {
  [[ $1 > $2 || $1 == "$2" ]]
}

getbyte () {
  printf -v $1 %d \'${2:$3:1}
}

gt? () {
  [[ $1 > $2 ]]
}

hex () {
  [[ $2 == *[^+\-[:digit:]a-fx]* ]] && {
    printf -v $1 %s 0
    return
  }
  case $2 in
    0x*|0X* ) printf -v $1 %d $2        ;;
    -*      ) printf -v $1 %d -0x${2#-} ;;
    *       ) printf -v $1 %d 0x$2      ;;
  esac
}

index () {
  local -n ref_=$1
  local target_=$2
  local search_=$3
  local i_
  local offset=${4:-0}

  ref_=''
  for (( i_ = $offset; i_ < ${#target_} - ${#search_} + 1; i_++ )); do
    eq? ${target_:i_:${#search_}} $search_ && {
      ref_=$i_
      return
    };:
  done
}

insert () {
  case $3 in
    -1  ) printf -v $1 %s ${2:0:$#+$3+1}$4          ;;
    -*  ) printf -v $1 %s ${2:0:$#+$3+1}$4${2:$3+1} ;;
    *   ) printf -v $1 %s ${2:0:$3}$4${2:$3}        ;;
  esac
}

inspect () {
  printf -v $1 %q $2
  [[ ${!1} == \$\'*\' ]] && return
  printf -v $1 '"%s"' ${!1}
}

le? () {
  [[ $1 < $2 || $1 == "$2" ]]
}

ljust () {
  local -n ref_=$1
  local padstr_=${4:- }
  local -i mod_
  local -i num_

  num_=($3-${#2})/${#padstr_}
  mod_=($3-${#2})%${#padstr_}
  times pad_ $padstr_ $num_
  ref_=$2$pad_${padstr_:0:mod_}
}

lstrip () {
  local -n ref_=$1

  ref_=${2%%[^[:space:]]*}
  ref_=${2#$ref_}
}

lt? () {
  [[ $1 < $2 ]]
}

next () {
  local -n ref_=$1
  local -i ord_
  local IFS=$IFS
  local chr_
  local i_
  local results_=()

  carry_=1
  for (( i_ = ${#2}; i_ > 0; i_-- )); do
    chr_=${2:i_-1:1}
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

ord () {
  printf -v $1 %d \'$2
}

partition () {
  local -n ref_=$1

  ref_=( ${2%%$3*} $3 ${2#*$3} )
}

rindex () {
  local -n ref_=$1
  local target_=$2
  local search_=$3
  local -i offset=${4:-${#target_}}
  local i_

  ref_=''
  for (( i_ = $offset - ${#search_}; i_ >= 0; i_-- )); do
    eq? ${target_:i_:${#search_}} $search_ && {
      ref_=$i_
      return
    };:
  done
}

rjust () {
  local -n ref_=$1
  local padstr_=${4:- }
  local -i mod_
  local -i num_

  num_="($3-${#2})/${#padstr_}"
  mod_="($3-${#2})%${#padstr_}"
  times pad_ $padstr_ $num_
  ref_=$pad_${padstr_:0:mod_}$2
}

rpartition () {
  local -n ref_=$1

  ref_=( ${2%$3*} $3 ${2##*$3} )
}

rstrip () {
  local -n ref_=$1

  ref_=${2##*[^[:space:]]}
  ref_=${2%$ref_}
}

scan () {
  local -n ref_=$1
  local target_=$2
  local pattern_=${3#/}

  pattern_=${pattern_%/}
  ref_=()
  while [[ $target_ =~ $pattern_ ]]; do
    ref_+=( $BASH_REMATCH )
    target_=${target_#*$BASH_REMATCH}
  done
}

split () {
  local -n ref_=$1; shift
  local delim_=${2:-[[:space:]]}

  while [[ $1 != ${1/$delim_} ]]; do
    ref_+=( ${1%%$delim_*} )
    set -- "${1#*$delim_}"
  done
  ref_+=( $1 )
}

strip () {
  lstrip __ $2
  rstrip $1 $__
}

times () {
  local -n ref_=$1
  local i_

  ref_=''
  for (( i_ = 0; i_ < $3; i_++ )); do
    ref_+=$2
  done
}
