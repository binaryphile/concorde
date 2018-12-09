IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/as module a=$shpec_Dir/lib/concorde.array.bash

describe all
  it "returns true if none of the elements return false"
    source $shpec_Dir/lib/as module s=$shpec_Dir/lib/concorde.bash
    samples=( zero one two )
    a.all samples s.present?
    assert equal 0 $?
  ti

  it "returns false if any of the elements return false"
    source $shpec_Dir/lib/as module s=$shpec_Dir/lib/concorde.bash
    samples=( zero one two )
    ! a.all samples s.blank?
    assert equal 0 $?
  ti
end_describe

describe any
  it "returns true if one of the elements returns true"
    source $shpec_Dir/lib/as module s=$shpec_Dir/lib/concorde.bash
    samples=( zero one '' )
    a.any samples s.blank?
    assert equal 0 $?
  ti

  it "returns false if all of the elements return false"
    source $shpec_Dir/lib/as module s=$shpec_Dir/lib/concorde.bash
    samples=( zero one two )
    ! a.any samples s.blank?
    assert equal 0 $?
  ti
end_describe

describe join
  it "joins strings with no delimiter"
    samples=( a b c )
    a.join result samples ''
    assert equal abc $result
  ti

  it "joins strings with a multicharacter delimiter"
    samples=( a b c )
    a.join result samples --
    assert equal a--b--c $result
  ti
end_describe
