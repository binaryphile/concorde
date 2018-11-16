concorde_Dir=$(dirname $(readlink -f $BASH_SOURCE))
source $concorde_Dir/module
module.already_loaded? && return

source module cor=$concorde_Dir/concorde.core.bash
source module str=$concorde_Dir/concorde.string.bash
