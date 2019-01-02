IFS=$'\n'
set -o noglob

shpec_Dir=$(readlink -f $(dirname $BASH_SOURCE)/..)
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/concorde.path.bash

describe executable?
  alias setup='dir=$(mktemp -d) || return'
  alias teardown='rm -rf $dir'

  it "identifies an executable file"
    touch $dir/file
    chmod 755 $dir/file
    executable? $dir/file
    assert equal 0 $?
  ti

  it "identifies an executable directory"
    chmod 755 $dir
    executable? $dir
    assert equal 0 $?
  ti

  it "doesn't identify an non-executable file"
    touch $dir/file
    ! executable? $dir/file
    assert equal 0 $?
  ti

  it "doesn't identify a non-executable directory"
    chmod 664 $dir
    ! executable? $dir
    assert equal 0 $?
  ti

  it "identifies a link to an executable file"
    touch $dir/file
    chmod 755 $dir/file
    ln -s file $dir/link
    executable? $dir/link
    assert equal 0 $?
  ti

  it "identifies a link to an executable directory"
    ln -s $dir $dir/link
    executable? $dir/link
    assert equal 0 $?
  ti

  it "doesn't identify a link to a non-executable file"
    touch $dir/file
    ln -s file $dir/link
    ! executable? $dir/link
    assert equal 0 $?
  ti

  it "doesn't identify a link to a non-executable directory"
    mkdir -m 664 $dir/dir
    ln -s $dir/dir $dir/link
    ! executable? $dir/link
    assert equal 0 $?
  ti
end_describe
