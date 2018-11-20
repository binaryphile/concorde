IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/module s=$shpec_Dir/lib/concorde.string.bash

describe *
  it "generates copies"
    s.* sample 2 result
    assert equal samplesample $result
  ti
end_describe

describe blank?
  it "is true if no argument"
    s.blank?
    assert equal 0 $?
  ti

  it "is true if the argument is empty"
    s.blank? ''
    assert equal 0 $?
  ti

  it "is false if the argument is non-empty"
    ! s.blank? a
    assert equal 0 $?
  ti
end_describe

describe compare
  it "returns -1 if the string is less than another"
    s.compare a b result
    assert equal -1 $result
  ti

  it "returns 0 if the string is the same as another"
    s.compare a a result
    assert equal 0 $result
  ti

  it "returns 1 if the string is greater than another"
    s.compare b a result
    assert equal 1 $result
  ti
end_describe

describe downcase
  it "lowers the case of all letters in the string"
    s.downcase hEllO result
    assert equal hello $result
  ti
end_describe

describe eq?
  it "returns true for equal strings"
    ! s.eq? sample sample
    assert unequal 0 $?
  ti

  it "returns false for unequal strings"
    ! s.eq? sample1 sample
    assert equal 0 $?
  ti
end_describe

describe ge?
  it "returns true for a greater string comparison"
    s.ge? b a
    assert equal 0 $?
  ti

  it "returns true for an equal string comparison"
    s.ge? a a
    assert equal 0 $?
  ti

  it "returns false for a lesser string comparison"
    ! s.ge? a b
    assert equal 0 $?
  ti
end_describe

describe gsub
  it "substitutes all occurrences of a pattern"
    s.gsub hello [aeiou] * result
    assert equal h*ll* $result
  ti
end_describe

describe gt?
  it "returns true for a greater string comparison"
    s.gt? b a
    assert equal 0 $?
  ti

  it "returns false for an equal string comparison"
    ! s.gt? a a
    assert equal 0 $?
  ti

  it "returns false for a lesser string comparison"
    ! s.gt? a b
    assert equal 0 $?
  ti
end_describe

describe include?
  it "returns true if one string includes the other"
    s.include? sample ampl
    assert equal 0 $?
  ti

  it "returns false if one string doesn't include the other"
    ! s.include? sample blah
    assert equal 0 $?
  ti
end_describe

describe index
  it "returns the index of 'e' in 'hello'"
    s.index hello e index
    assert equal 1 "$index"
  ti

  it "returns the index of 'lo' in 'hello'"
    s.index hello lo index
    assert equal 3 "$index"
  ti

  it "doesn't return the index of 'a' in 'hello'"
    s.index hello a index
    assert equal '' "$index"
  ti

  it "starts at an offset"
    s.index hello l index offset=3
    assert equal 3 "$index"
  ti
end_describe

describe le?
  it "returns true for a lesser string comparison"
    s.le? a b
    assert equal 0 $?
  ti

  it "returns true for an equal string comparison"
    s.le? a a
    assert equal 0 $?
  ti

  it "returns false for a greater string comparison"
    ! s.le? b a
    assert equal 0 $?
  ti
end_describe

describe left
  it "returns the left side of a string"
    s.left hello 2 result
    assert equal he $result
  ti
end_describe

describe length
  it "returns the character length of a string"
    s.length hello result
    assert equal 5 $result
  ti
end_describe

describe lower
  it "lowers the case of all letters in the string"
    s.lower hEllO result
    assert equal hello $result
  ti
end_describe

describe lstrip
  it "strips whitespace from the left of a string"
    s.lstrip " whitespace " result
    assert equal "whitespace " $result
  ti
end_describe

describe lt?
  it "returns true for a lesser string comparison"
    s.lt? a b
    assert equal 0 $?
  ti

  it "returns false for an equal string comparison"
    ! s.lt? a a
    assert equal 0 $?
  ti

  it "returns false for a greater string comparison"
    ! s.lt? b a
    assert equal 0 $?
  ti
end_describe

describe partition
  it "partitions a string into an array"
    s.partition "Spam eggs spam spam and ham" spam results
    expecteds=( "Spam eggs " spam " spam and ham" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe present?
  it "is false if no argument"
    ! s.present?
    assert equal 0 $?
  ti

  it "is false if the argument is empty"
    ! s.present? ''
    assert equal 0 $?
  ti

  it "is true if the argument is non-empty"
    s.present? a
    assert equal 0 $?
  ti
end_describe

describe replace
  it "substitutes all occurrences of a pattern"
    s.replace hello [aeiou] * result
    assert equal h*ll* $result
  ti
end_describe

describe reverse
  it "reverses a string"
    s.reverse stressed result
    assert equal desserts $result
  ti
end_describe

describe right
  it "returns the right side of a string"
    s.right hello 2 result
    assert equal lo $result
  ti
end_describe

describe rindex
  it "returns the index of 'e' in 'hello'"
    s.rindex hello e index
    assert equal 1 "$index"
  ti

  it "returns the index of 'l' in 'hello'"
    s.rindex hello l index
    assert equal 3 "$index"
  ti

  it "doesn't return the index of 'a' in 'hello'"
    s.rindex hello a index
    assert equal '' "$index"
  ti
end_describe

describe rpartition
  it "partitions a string into an array"
    s.rpartition "Spam eggs spam spam and ham" spam results
    expecteds=( "Spam eggs spam " spam " and ham" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe rstrip
  it "strips whitespace from the right of a string"
    s.rstrip " whitespace " result
    assert equal " whitespace" $result
  ti
end_describe

describe split
  it "splits a string into an array"
    s.split " now's  the time" '' results
    expecteds=( "now's" "the" "time" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "splits a string into an array on space"
    s.split " now's  the time" ' ' results
    expecteds=( "now's" "the" "time" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "splits on a string"
    s.split "mellow yellow" ello results
    expecteds=( m "w y" w )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe strip
  it "strips whitespace from both sides of a string"
    s.strip " whitespace " result
    assert equal whitespace $result
  ti
end_describe

describe substr
  it "returns a string based on start and end position"
    s.substr hello 2 4 result
    assert equal ll $result
  ti
end_describe

describe upcase
  it "raises the case of all letters in the string"
    s.upcase hEllO result
    assert equal HELLO $result
  ti
end_describe

describe upper
  it "raises the case of all letters in the string"
    s.upper hEllO result
    assert equal HELLO $result
  ti
end_describe
