concorde_array_Dir=$(dirname $(readlink -f $BASH_SOURCE))
source $concorde_array_Dir/as module
module.already_loaded && return

all () {
  local item_

  for item_ in $1; do
    $2 $item_ || return
  done
}

any () {
  for item_ in $1; do
    $2 $item_ && return
  done
}

include? () {
  [[ $IFS$1$IFS == *"$IFS$2$IFS"* ]]
}

join () {
  local -n ref_=$1
  local item_

  for item_ in $2; do
    ref_+=$item_$3
  done
  ref_=${ref_%$3}
}
