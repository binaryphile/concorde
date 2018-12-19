concorde_integer_Dir=$(dirname $(readlink -f $BASH_SOURCE))
source $concorde_integer_Dir/as module
module.already_loaded && return
