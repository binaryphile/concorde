IFS=$'\n'
set -o noglob

export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir -p $TMPDIR

set --
Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $Dir/lib/shpec-helper.bash
