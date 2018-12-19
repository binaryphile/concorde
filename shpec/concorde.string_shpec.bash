IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/as module s=$shpec_Dir/lib/concorde.string.bash

export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir -p $TMPDIR

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

describe center
  it "doesn't extend a too short width"
    s.center result hello 4
    assert equal hello $result
  ti

  it "centers in a wider area"
    s.center result hello 20
    assert equal '       hello        ' $result
  ti

  it "centers with a padstr"
    s.center result hello 20 123
    assert equal '1231231hello12312312' $result
  ti
end_describe

describe chars
  it "converts a string to an array of characters"
    s.chars results abc
    expecteds=( a b c )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe chomp
  it "doesn't chomp nothing"
    s.chomp result hello
    assert equal hello "$result"
  ti

  it "chomps newline"
    s.chomp result $'hello\n'
    assert equal hello "$result"
  ti

  it "chomps carriage-return newline"
    s.chomp result $'hello\r\n'
    assert equal hello "$result"
  ti

  it "only chomps one qualifying trailer"
    s.chomp result $'hello\n\r'
    assert equal $'hello\n' "$result"
  ti

  it "chomps a carriage-return"
    s.chomp result $'hello\r'
    assert equal hello "$result"
  ti

  it "doesn't chomp a non-terminal newline"
    s.chomp result $'hello \n there'
    assert equal $'hello \n there' "$result"
  ti

  it "chomps a specified trailer"
    s.chomp result hello llo
    assert equal he "$result"
  ti

  it "removes trailing carriage-return newlines if given an empty string"
    s.chomp result $'hello\r\n\r\n' ''
    assert equal hello "$result"
  ti

  it "doesn't remove trailing newlines if given an empty string"
    s.chomp result $'hello\r\n\r\r\n' ''
    assert equal $'hello\r\n\r' "$result"
  ti
end_describe

describe chop
  it "chops carriage-return newline"
    s.chop result $'string\r\n'
    assert equal string "$result"
  ti

  it "chops carriage-return"
    s.chop result $'string\n\r'
    assert equal $'string\n' "$result"
  ti

  it "chops newline"
    s.chop result $'string\n'
    assert equal string "$result"
  ti

  it "chops the last letter"
    s.chop result string
    assert equal strin "$result"
  ti

  it "chops an empty string"
    s.chop result x
    s.chop result "$result"
    assert equal '' "$result"
  ti
end_describe

describe chr
  it "returns one character from the beginning of a string"
    s.chr result abc
    assert equal a $result
  ti
end_describe

describe codepoints
  it "returns an array of the integers for the characters"
    s.codepoints result $'hello\u0639'
    expecteds=( 104 101 108 108 111 1593 )
    assert equal "${expecteds[*]}" "${result[*]}"
  ti
end_describe

describe compare
  it "returns -1 if the string is less than another"
    s.compare result a b
    assert equal -1 $result
  ti

  it "returns 0 if the string is the same as another"
    s.compare result a a
    assert equal 0 $result
  ti

  it "returns 1 if the string is greater than another"
    s.compare result b a
    assert equal 1 $result
  ti
end_describe

describe count
  it "counts ls and os"
    s.count result "hello world" lo
    assert equal 5 $result
  ti

  it "counts the intersection of two strings"
    s.count result "hello world" lo o
    assert equal 2 $result
  ti

  it "counts negated"
    s.count result "hello world" hello ^l
    assert equal 4 $result
  ti

  it "counts a range"
    s.count result "hello world" ej-m
    assert equal 4 $result
  ti

  it "escapes ^"
    s.count result "hello^world" '\^aeiou'
    assert equal 4 $result
  ti

  it "escapes -"
    s.count result "hello-world" 'a\-eo'
    assert equal 4 $result
  ti
end_describe

describe delete
  it "deletes a couple strings"
    s.delete result hello l lo
    assert equal heo $result
  ti

  it "deletes a string"
    s.delete result hello lo
    assert equal he $result
  ti

  it "deletes a negation"
    s.delete result ^hello aeiou ^e
    assert equal ^hell $result
  ti

  it "deletes a range"
    s.delete result he-llo ej-m
    assert equal h-o $result
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
    s.getbyte result hello 2
    assert equal 108 $result
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
    s.hex result 0x0a
    assert equal 10 $result
  ti

  it "parses a sign"
    s.hex result -1234
    assert equal -4660 $result
  ti

  it "parses 0"
    s.hex result 0
    assert equal 0 $result
  ti

  it "returns 0 on error"
    s.hex result wombat
    assert equal 0 $result
  ti
end_describe

describe index
  it "returns the index of 'e' in 'hello'"
    s.index result hello e
    assert equal 1 $result
  ti

  it "returns the index of 'lo' in 'hello'"
    s.index result hello lo
    assert equal 3 $result
  ti

  it "doesn't return the index of 'a' in 'hello'"
    s.index result hello a
    assert equal '' "$result"
  ti

  it "starts at an offset"
    s.index result hello l 3
    assert equal 3 $result
  ti
end_describe

describe insert
  it "inserts before an index"
    s.insert result abcd 0 X
    assert equal Xabcd $result
  ti

  it "inserts before another index"
    s.insert result abcd 3 X
    assert equal abcXd $result
  ti

  it "inserts before yet another index"
    s.insert result abcd 4 X
    assert equal abcdX $result
  ti

  it "inserts before a negative index"
    s.insert result abcd -3 X
    assert equal abXcd $result
  ti

  it "inserts before another negative index"
    s.insert result abcd -1 X
    assert equal abcdX $result
  ti
end_describe

describe inspect
  it "returns a quoted string"
    s.inspect result $'hel\bo'
    assert equal "$'hel\bo'" $result
  ti

  it "returns a quoted string"
    s.inspect result hello
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

describe ljust
  it "returns the string if the pad is shorter"
    s.ljust result hello 4
    assert equal hello $result
  ti

  it "returns a padded string"
    s.ljust result hello 20
    assert equal 'hello               ' $result
  ti

  it "returns a given pad"
    s.ljust result hello 20 1234
    assert equal hello123412341234123 $result
  ti
end_describe

describe lstrip
  it "strips whitespace from the left of a string"
    s.lstrip result " whitespace "
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

describe next
  it "increments a letter"
    s.next result abcd
    assert equal abce $result
  ti

  it "increments a number"
    s.next result THX1138
    assert equal THX1139 $result
  ti

  it "skips non-alnums"
    s.next result '<<koala>>'
    assert equal '<<koalb>>' $result
  ti

  it "carries on lowercase letters and numbers"
    s.next result 1999zzz
    assert equal 2000aaa $result
  ti

  it "carries on uppercase letters and numbers"
    s.next result ZZZ9999
    assert equal AAAA0000 $result
  ti
end_describe

describe ord
  it "returns the ordinal of a one-character string"
    s.ord result a
    assert equal 97 $result
  ti
end_describe

describe partition
  it "partitions a string into an array"
    s.partition results "Spam eggs spam spam and ham" spam
    expecteds=( "Spam eggs " spam " spam and ham" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe rindex
  it "returns the index of 'e' in 'hello'"
    s.rindex result hello e
    assert equal 1 "$result"
  ti

  it "returns the index of 'l' in 'hello'"
    s.rindex result hello l
    assert equal 3 "$result"
  ti

  it "doesn't return the index of 'a' in 'hello'"
    s.rindex result hello a
    assert equal '' "$result"
  ti
end_describe

describe rjust
  it "returns the string if the pad is shorter"
    s.rjust result hello 4
    assert equal hello $result
  ti

  it "returns a padded string"
    s.rjust result hello 20
    assert equal '               hello' $result
  ti

  it "returns a given pad"
    s.rjust result hello 20 1234
    assert equal 123412341234123hello $result
  ti
end_describe

describe rpartition
  it "partitions a string into an array"
    s.rpartition results "Spam eggs spam spam and ham" spam
    expecteds=( "Spam eggs spam " spam " and ham" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe rstrip
  it "strips whitespace from the right of a string"
    s.rstrip result " whitespace "
    assert equal " whitespace" $result
  ti
end_describe

describe scan
  it "scans by word"
    s.scan results "cruel world" /[[:alnum:]_]+/
    expecteds=( cruel world )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "scans letters"
    s.scan results "cruel world" /.../
    expecteds=( cru 'el ' wor )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe split
  it "splits a string into an array"
    s.split results " now's  the time" ''
    expecteds=( "now's" "the" "time" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "splits a string into an array on space"
    s.split results " now's  the time" ' '
    expecteds=( "now's" "the" "time" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "splits on a string"
    s.split results "mellow yellow" ello
    expecteds=( m "w y" w )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe strip
  it "strips whitespace from both sides of a string"
    s.strip result " whitespace "
    assert equal whitespace $result
  ti
end_describe

describe times
  it "generates copies"
    s.times result sample 2
    assert equal samplesample $result
  ti
end_describe
