concorde_array_Dir=$(dirname $(readlink -f $BASH_SOURCE))
source $concorde_array_Dir/as module
module.already_loaded && return

all () {
  local -n ary_=$1
  local item_

  for item_ in ${ary_[*]}; do
    $2 $item_ || return
  done
}

any () {
  local -n ary_=$1
  local item_

  for item_ in "${ary_[@]}"; do
    $2 $item_ && return
  done
}

join () {
  local -n ref_=$1
  local -n ary_=$2
  local item_

  for item_ in ${ary_[*]}; do
    ref_+=$item_$3
  done
  ref_=${ref_%$3}
}
