IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/concorde.bash

describe all
  it "returns true if none of the elements return false"
    set -- one two three
    ary.all "$*" present?
    assert equal 0 $?
  ti

  it "returns false if any of the elements return false"
    set -- one two three
    ! ary.all "$*" blank?
    assert equal 0 $?
  ti
end_describe

describe any
  it "returns true if one of the elements returns true"
    set -- one two ' '
    ary.any "$*" blank?
    assert equal 0 $?
  ti

  it "returns false if all of the elements return false"
    set -- one two
    ! ary.any "$*" blank?
    assert equal 0 $?
  ti
end_describe

describe include?
  it "detects an element of an array"
    set -- one two three
    ary.include? "$*" two
    assert equal 0 $?
  ti

  it "doesn't detect a nonelement of an array"
    set -- one two three
    ! ary.include? "$*" four
    assert equal 0 $?
  ti
end_describe

describe join
  it "joins strings with no delimiter"
    set -- a b c
    ary.join result "$*" ''
    assert equal abc $result
  ti

  it "joins strings with a multicharacter delimiter"
    set -- a b c
    ary.join result "$*" --
    assert equal a--b--c $result
  ti
end_describe
