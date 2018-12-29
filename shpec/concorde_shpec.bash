IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/concorde.bash

export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir -p $TMPDIR

describe concorde
  it "loads core"
    [[ $(type -t get) == function ]]
    assert equal 0 $?
  ti
end_describe
