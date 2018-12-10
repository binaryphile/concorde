IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/concorde.bash

describe all
  it "returns true if none of the elements return false"
    samples=( zero one two )
    ary.all samples present?
    assert equal 0 $?
  ti

  it "returns false if any of the elements return false"
    samples=( zero one two )
    ! ary.all samples blank?
    assert equal 0 $?
  ti
end_describe

describe any
  it "returns true if one of the elements returns true"
    samples=( zero one '' )
    ary.any samples blank?
    assert equal 0 $?
  ti

  it "returns false if all of the elements return false"
    samples=( zero one two )
    ! ary.any samples blank?
    assert equal 0 $?
  ti
end_describe

describe join
  it "joins strings with no delimiter"
    samples=( a b c )
    ary.join result samples ''
    assert equal abc $result
  ti

  it "joins strings with a multicharacter delimiter"
    samples=( a b c )
    ary.join result samples --
    assert equal a--b--c $result
  ti
end_describe
