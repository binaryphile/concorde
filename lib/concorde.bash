concorde_Dir=$(dirname $(readlink -f $BASH_SOURCE))

source $concorde_Dir/as module            \
  str=$concorde_Dir/concorde.string.bash  \
  ary=$concorde_Dir/concorde.array.bash
