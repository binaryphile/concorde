IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/../lib
source $shpec_Dir/shpec-helper.bash
source $shpec_Dir/module a=$shpec_Dir/concorde.array.bash

describe all
  it "returns true if none of the elements return false"
    source $shpec_Dir/module s=$shpec_Dir/concorde.string.bash
    samples=( zero one two )
    a.all s.present? "${samples[*]}"
    assert equal 0 $?
  ti

  it "returns false if any of the elements return false"
    source $shpec_Dir/module s=$shpec_Dir/concorde.string.bash
    samples=( zero one two )
    ! a.all s.blank? "${samples[*]}"
    assert equal 0 $?
  ti
end_describe

describe join
  it "joins strings with no delimiter"
    samples=( a b c )
    a.join "${samples[*]}" '' result
    assert equal abc $result
  ti

  it "joins strings with a multicharacter delimiter"
    samples=( a b c )
    a.join "${samples[*]}" -- result
    assert equal a--b--c $result
  ti
end_describe

