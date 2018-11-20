IFS=$'\n'
set -o noglob

export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir -p $TMPDIR

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
