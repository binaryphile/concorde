IFS=$'\n'
set -o noglob

shpec_Dir=$(readlink -f $(dirname $BASH_SOURCE)/..)
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/concorde.file.bash

describe executable_file?
  alias setup='dir=$(mktemp -d) || return'
  alias teardown='rm -rf $dir'

  it "identifies an executable file"
    touch $dir/file
    chmod 755 $dir/file
    executable? $dir/file
    assert equal 0 $?
  ti

  it "doesn't identify an executable directory"
    ! executable? $dir
    assert equal 0 $?
  ti
end_describe
