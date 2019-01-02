IFS=$'\n'
set -o noglob

shpec_Dir=$(readlink -f $(dirname $BASH_SOURCE)/..)/lib
source $shpec_Dir/../shpec/shpec-helper.bash
source $shpec_Dir/concorde.bash

export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir -p $TMPDIR

describe concorde
  it "loads core"
    [[ $(type -t get) == function ]]
    assert equal 0 $?
  ti

  it "loads string"
    [[ -v _modules_[$shpec_Dir/concorde.string.bash] ]]
    assert equal 0 $?
  ti

  it "loads array"
    [[ -v _modules_[$shpec_Dir/concorde.array.bash] ]]
    assert equal 0 $?
  ti

  it "loads file"
    [[ -v _modules_[$shpec_Dir/concorde.file.bash] ]]
    assert equal 0 $?
  ti

  it "loads path"
    [[ -v _modules_[$shpec_Dir/concorde.path.bash] ]]
    assert equal 0 $?
  ti
end_describe
