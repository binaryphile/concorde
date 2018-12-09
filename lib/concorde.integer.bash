concorde_integer_Dir=$(dirname $(readlink -f $BASH_SOURCE))
source $concorde_integer_Dir/as module
module.already_loaded && return

times () {
  local -n ref_=$1
  local i_

  ref_=''
  for (( i_ = 0; i_ < $2; i_++ )); do
    ref_+=$3
  done
}
