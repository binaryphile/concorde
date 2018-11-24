concorde_Dir=$(dirname $(readlink -f $BASH_SOURCE))

source $concorde_Dir/as module          \
  s=$concorde_Dir/concorde.string.bash  \
  a=$concorde_Dir/concorde.array.bash
