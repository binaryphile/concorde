concorde_array_Dir=$(dirname $(readlink -f $BASH_SOURCE))
source $concorde_array_Dir/as module
module.already_loaded && return

all () {
  local item

  for item in $2; do
    $1 $item || return
  done
}

join () {
  local -n ref_=$3
  local item_

  for item_ in $1; do
    ref_+=$item_$2
  done
  ref_=${ref_%$2}
}
