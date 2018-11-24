IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/as module s=$shpec_Dir/lib/concorde.string.bash

describe ascii_only?
  it "is true if only ascii characters"
    s.ascii_only? abc
    assert equal 0 $?
  ti

  it "is false if there are non-ascii characters"
    printf -v sample '\xE2\x98\xA0'
    ! s.ascii_only? $sample
    assert equal 0 $?
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

  it "is true if the argument is whitespace"
    s.blank? $' \t\n'
    assert equal 0 $?
  ti

  it "is false if the argument is non-empty"
    ! s.blank? a
    assert equal 0 $?
  ti
end_describe

describe capitalize
  it "capitalizes a word"
    s.capitalize HELLO result
    assert equal Hello $result
  ti
end_describe

describe center
  it "doesn't extend a too short width"
    s.center hello 4 result
    assert equal hello $result
  ti

  it "centers in a wider area"
    s.center hello 20 result
    assert equal '       hello        ' $result
  ti

  it "centers with a padstr"
    s.center hello 20 result 123
    assert equal '1231231hello12312312' $result
  ti
end_describe

describe chars
  it "converts a string to an array of characters"
    s.chars abc results
    expecteds=( a b c )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe chomp
  it "doesn't chomp nothing"
    s.chomp hello result
    assert equal hello "$result"
  ti

  it "chomps newline"
    s.chomp $'hello\n' result
    assert equal hello "$result"
  ti

  it "chomps carriage-return newline"
    s.chomp $'hello\r\n' result
    assert equal hello "$result"
  ti

  it "only chomps one qualifying trailer"
    s.chomp $'hello\n\r' result
    assert equal $'hello\n' "$result"
  ti

  it "chomps a carriage-return"
    s.chomp $'hello\r' result
    assert equal hello "$result"
  ti

  it "doesn't chomp a non-terminal newline"
    s.chomp $'hello \n there' result
    assert equal $'hello \n there' "$result"
  ti

  it "chomps a specified trailer"
    s.chomp hello llo result
    assert equal he "$result"
  ti

  it "removes trailing carriage-return newlines if given an empty string"
    s.chomp $'hello\r\n\r\n' '' result
    assert equal hello "$result"
  ti

  it "doesn't remove trailing newlines if given an empty string"
    s.chomp $'hello\r\n\r\r\n' '' result
    assert equal $'hello\r\n\r' "$result"
  ti
end_describe

describe chop
  it "chops carriage-return newline"
    s.chop $'string\r\n' result
    assert equal string "$result"
  ti

  it "chops carriage-return"
    s.chop $'string\n\r' result
    assert equal $'string\n' "$result"
  ti

  it "chops newline"
    s.chop $'string\n' result
    assert equal string "$result"
  ti

  it "chops the last letter"
    s.chop string result
    assert equal strin "$result"
  ti

  it "chops an empty string"
    s.chop x result
    s.chop "$result" result
    assert equal '' "$result"
  ti
end_describe

describe chr
  it "returns one character from the beginning of a string"
    s.chr abc result
    assert equal a $result
  ti
end_describe

describe codepoints
  it "returns an array of the integers for the characters"
    s.codepoints $'hello\u0639' result
    expecteds=( 104 101 108 108 111 1593 )
    assert equal "${expecteds[*]}" "${result[*]}"
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

describe count
  it "counts ls and os"
    s.count "hello world" lo result
    assert equal 5 $result
  ti

  it "counts the intersection of two strings"
    s.count "hello world" lo o result
    assert equal 2 $result
  ti

  it "counts negated"
    s.count "hello world" hello ^l result
    assert equal 4 $result
  ti

  it "counts a range"
    s.count "hello world" ej-m result
    assert equal 4 $result
  ti

  it "escapes ^"
    s.count "hello^world" '\^aeiou' result
    assert equal 4 $result
  ti

  it "escapes -"
    s.count "hello-world" 'a\-eo' result
    assert equal 4 $result
  ti
end_describe

describe delete
  it "deletes a couple strings"
    s.delete hello l lo result
    assert equal heo $result
  ti

  it "deletes a string"
    s.delete hello lo result
    assert equal he $result
  ti

  it "deletes a negation"
    s.delete ^hello aeiou ^e result
    assert equal ^hell $result
  ti

  it "deletes a range"
    s.delete he-llo ej-m result
    assert equal h-o $result
  ti
end_describe

describe downcase
  it "lowers the case of all letters in the string"
    s.downcase hEllO result
    assert equal hello $result
  ti
end_describe

describe dump
  it "dumps an escaped representation"
    s.dump $'hello \n \'\'' result
    assert equal "$'hello \n \'\''" $result
  ti
end_describe

describe empty?
  it "returns true for no argument"
    s.empty?
    assert equal 0 $?
  ti

  it "returns true for an empty string"
    s.empty? ''
    assert equal 0 $?
  ti

  it "returns false for a non-empty string"
    ! s.empty? a
    assert equal 0 $?
  ti
end_describe

describe end_with?
  it "returns true if the string ends with the argument"
    s.end_with? hello ello
    assert equal 0 $?
  ti

  it "returns true if the string ends with one of the arguments"
    s.end_with? hello heaven ello
    assert equal 0 $?
  ti

  it "returns false if the string doesn't end with one of the arguments"
    ! s.end_with? hello heaven paradise
    assert equal 0 $?
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

describe getbyte
  it "returns a byte from the indexed string"
    s.getbyte hello 2 result
    assert equal 108 $result
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

describe hex
  it "returns a hex value"
    s.hex 0x0a result
    assert equal 10 $result
  ti

  it "parses a sign"
    s.hex -1234 result
    assert equal -4660 $result
  ti

  it "parses 0"
    s.hex 0 result
    assert equal 0 $result
  ti

  it "returns 0 on error"
    s.hex wombat result
    assert equal 0 $result
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

describe insert
  it "inserts before an index"
    s.insert abcd 0 X result
    assert equal Xabcd $result
  ti

  it "inserts before another index"
    s.insert abcd 3 X result
    assert equal abcXd $result
  ti

  it "inserts before yet another index"
    s.insert abcd 4 X result
    assert equal abcdX $result
  ti

  it "inserts before a negative index"
    s.insert abcd -3 X result
    assert equal abXcd $result
  ti

  it "inserts before another negative index"
    s.insert abcd -1 X result
    assert equal abcdX $result
  ti
end_describe

describe inspect
  it "returns a quoted string"
    s.inspect $'hel\bo' result
    assert equal "$'hel\bo'" $result
  ti

  it "returns a quoted string"
    s.inspect hello result
    assert equal '"hello"' $result
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

  it "is false if the argument is whitespace"
    ! s.present? $' \t\n'
    assert equal 0 $?
  ti

  it "is true if the argument is non-empty"
    s.present? a
    assert equal 0 $?
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

describe times
  it "generates copies"
    s.times sample 2 result
    assert equal samplesample $result
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
