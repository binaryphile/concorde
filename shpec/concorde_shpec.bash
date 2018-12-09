IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/concorde.bash

export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir -p $TMPDIR

describe alias_var
  alias_var sample

  it "captures builtin output"
    samplef () {
      local sample

      sample = echo text
      echo $sample
    }
    result=$(samplef)
    assert equal text $result
  ti

  it "feeds the variable as the first argument to a function"
    assign () {
      printf -v $1 %s $2
    }
    samplef () {
      local sample

      sample = assign text
      echo $sample
    }
    result=$(samplef)
    assert equal text $result
  ti
end_describe

describe ascii_only?
  it "is true if only ascii characters"
    ascii_only? abc
    assert equal 0 $?
  ti

  it "is false if there are non-ascii characters"
    printf -v sample '\xE2\x98\xA0'
    ! ascii_only? $sample
    assert equal 0 $?
  ti
end_describe

describe blank?
  it "is true if no argument"
    blank?
    assert equal 0 $?
  ti

  it "is true if the argument is empty"
    blank? ''
    assert equal 0 $?
  ti

  it "is true if the argument is whitespace"
    blank? $' \t\n'
    assert equal 0 $?
  ti

  it "is false if the argument is non-empty"
    ! blank? a
    assert equal 0 $?
  ti
end_describe

describe capitalize
  it "capitalizes a word"
    capitalize result HELLO
    assert equal Hello $result
  ti
end_describe

describe center
  it "doesn't extend a too short width"
    center result hello 4
    assert equal hello $result
  ti

  it "centers in a wider area"
    center result hello 20
    assert equal '       hello        ' $result
  ti

  it "centers with a padstr"
    center result hello 20 123
    assert equal '1231231hello12312312' $result
  ti
end_describe

describe chars
  it "converts a string to an array of characters"
    chars results abc
    expecteds=( a b c )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe chomp
  it "doesn't chomp nothing"
    chomp result hello
    assert equal hello "$result"
  ti

  it "chomps newline"
    chomp result $'hello\n'
    assert equal hello "$result"
  ti

  it "chomps carriage-return newline"
    chomp result $'hello\r\n'
    assert equal hello "$result"
  ti

  it "only chomps one qualifying trailer"
    chomp result $'hello\n\r'
    assert equal $'hello\n' "$result"
  ti

  it "chomps a carriage-return"
    chomp result $'hello\r'
    assert equal hello "$result"
  ti

  it "doesn't chomp a non-terminal newline"
    chomp result $'hello \n there'
    assert equal $'hello \n there' "$result"
  ti

  it "chomps a specified trailer"
    chomp result hello llo
    assert equal he "$result"
  ti

  it "removes trailing carriage-return newlines if given an empty string"
    chomp result $'hello\r\n\r\n' ''
    assert equal hello "$result"
  ti

  it "doesn't remove trailing newlines if given an empty string"
    chomp result $'hello\r\n\r\r\n' ''
    assert equal $'hello\r\n\r' "$result"
  ti
end_describe

describe chop
  it "chops carriage-return newline"
    chop result $'string\r\n'
    assert equal string "$result"
  ti

  it "chops carriage-return"
    chop result $'string\n\r'
    assert equal $'string\n' "$result"
  ti

  it "chops newline"
    chop result $'string\n'
    assert equal string "$result"
  ti

  it "chops the last letter"
    chop result string
    assert equal strin "$result"
  ti

  it "chops an empty string"
    chop result x
    chop result "$result"
    assert equal '' "$result"
  ti
end_describe

describe chr
  it "returns one character from the beginning of a string"
    chr result abc
    assert equal a $result
  ti
end_describe

describe codepoints
  it "returns an array of the integers for the characters"
    codepoints result $'hello\u0639'
    expecteds=( 104 101 108 108 111 1593 )
    assert equal "${expecteds[*]}" "${result[*]}"
  ti
end_describe

describe compare
  it "returns -1 if the string is less than another"
    compare result a b
    assert equal -1 $result
  ti

  it "returns 0 if the string is the same as another"
    compare result a a
    assert equal 0 $result
  ti

  it "returns 1 if the string is greater than another"
    compare result b a
    assert equal 1 $result
  ti
end_describe

describe count
  it "counts ls and os"
    count result "hello world" lo
    assert equal 5 $result
  ti

  it "counts the intersection of two strings"
    count result "hello world" lo o
    assert equal 2 $result
  ti

  it "counts negated"
    count result "hello world" hello ^l
    assert equal 4 $result
  ti

  it "counts a range"
    count result "hello world" ej-m
    assert equal 4 $result
  ti

  it "escapes ^"
    count result "hello^world" '\^aeiou'
    assert equal 4 $result
  ti

  it "escapes -"
    count result "hello-world" 'a\-eo'
    assert equal 4 $result
  ti
end_describe

describe delete
  it "deletes a couple strings"
    delete result hello l lo
    assert equal heo $result
  ti

  it "deletes a string"
    delete result hello lo
    assert equal he $result
  ti

  it "deletes a negation"
    delete result ^hello aeiou ^e
    assert equal ^hell $result
  ti

  it "deletes a range"
    delete result he-llo ej-m
    assert equal h-o $result
  ti
end_describe

describe downcase
  it "lowers the case of all letters in the string"
    downcase result hEllO
    assert equal hello $result
  ti
end_describe

describe dump
  it "dumps an escaped representation"
    dump result $'hello \n \'\''
    assert equal "$'hello \n \'\''" $result
  ti
end_describe

describe empty?
  it "returns true for no argument"
    empty?
    assert equal 0 $?
  ti

  it "returns true for an empty string"
    empty? ''
    assert equal 0 $?
  ti

  it "returns false for a non-empty string"
    ! empty? a
    assert equal 0 $?
  ti
end_describe

describe end_with?
  it "returns true if the string ends with the argument"
    end_with? hello ello
    assert equal 0 $?
  ti

  it "returns true if the string ends with one of the arguments"
    end_with? hello heaven ello
    assert equal 0 $?
  ti

  it "returns false if the string doesn't end with one of the arguments"
    ! end_with? hello heaven paradise
    assert equal 0 $?
  ti
end_describe

describe eq?
  it "returns true for equal strings"
    ! eq? sample sample
    assert unequal 0 $?
  ti

  it "returns false for unequal strings"
    ! eq? sample1 sample
    assert equal 0 $?
  ti
end_describe

describe ge?
  it "returns true for a greater string comparison"
    ge? b a
    assert equal 0 $?
  ti

  it "returns true for an equal string comparison"
    ge? a a
    assert equal 0 $?
  ti

  it "returns false for a lesser string comparison"
    ! ge? a b
    assert equal 0 $?
  ti
end_describe

describe getbyte
  it "returns a byte from the indexed string"
    getbyte result hello 2
    assert equal 108 $result
  ti
end_describe

describe gsub
  it "substitutes all occurrences of a pattern"
    gsub result hello [aeiou] *
    assert equal h*ll* $result
  ti
end_describe

describe gt?
  it "returns true for a greater string comparison"
    gt? b a
    assert equal 0 $?
  ti

  it "returns false for an equal string comparison"
    ! gt? a a
    assert equal 0 $?
  ti

  it "returns false for a lesser string comparison"
    ! gt? a b
    assert equal 0 $?
  ti
end_describe

describe hex
  it "returns a hex value"
    hex result 0x0a
    assert equal 10 $result
  ti

  it "parses a sign"
    hex result -1234
    assert equal -4660 $result
  ti

  it "parses 0"
    hex result 0
    assert equal 0 $result
  ti

  it "returns 0 on error"
    hex result wombat
    assert equal 0 $result
  ti
end_describe

describe include?
  it "returns true if one string includes the other"
    include? sample ampl
    assert equal 0 $?
  ti

  it "returns false if one string doesn't include the other"
    ! include? sample blah
    assert equal 0 $?
  ti
end_describe

describe index
  it "returns the index of 'e' in 'hello'"
    index result hello e
    assert equal 1 $result
  ti

  it "returns the index of 'lo' in 'hello'"
    index result hello lo
    assert equal 3 $result
  ti

  it "doesn't return the index of 'a' in 'hello'"
    index result hello a
    assert equal '' "$result"
  ti

  it "starts at an offset"
    index result hello l 3
    assert equal 3 $result
  ti
end_describe

describe insert
  it "inserts before an index"
    insert result abcd 0 X
    assert equal Xabcd $result
  ti

  it "inserts before another index"
    insert result abcd 3 X
    assert equal abcXd $result
  ti

  it "inserts before yet another index"
    insert result abcd 4 X
    assert equal abcdX $result
  ti

  it "inserts before a negative index"
    insert result abcd -3 X
    assert equal abXcd $result
  ti

  it "inserts before another negative index"
    insert result abcd -1 X
    assert equal abcdX $result
  ti
end_describe

describe inspect
  it "returns a quoted string"
    inspect result $'hel\bo'
    assert equal "$'hel\bo'" $result
  ti

  it "returns a quoted string"
    inspect result hello
    assert equal '"hello"' $result
  ti
end_describe

describe kwargs
  it "instantiates keyword arguments"
    samplef () {
      kwargs $*
      echo $sample
    }
    result=$(samplef sample=text)
    assert equal text $result
  ti
end_describe

describe le?
  it "returns true for a lesser string comparison"
    le? a b
    assert equal 0 $?
  ti

  it "returns true for an equal string comparison"
    le? a a
    assert equal 0 $?
  ti

  it "returns false for a greater string comparison"
    ! le? b a
    assert equal 0 $?
  ti
end_describe

describe left
  it "returns the left side of a string"
    left result hello 2
    assert equal he $result
  ti
end_describe

describe length
  it "returns the character length of a string"
    length result hello
    assert equal 5 $result
  ti
end_describe

describe lines
  it "returns an array from the lines"
    lines results $'hello\nthere'
    expecteds=( hello there )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "returns an array using a different separator"
    lines results $'hello\tthere' $'\t'
    expecteds=( hello there )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe ljust
  it "returns the string if the pad is shorter"
    ljust result hello 4
    assert equal hello $result
  ti

  it "returns a padded string"
    ljust result hello 20
    assert equal 'hello               ' $result
  ti

  it "returns a given pad"
    ljust result hello 20 1234
    assert equal hello123412341234123 $result
  ti
end_describe

describe lstrip
  it "strips whitespace from the left of a string"
    lstrip result " whitespace "
    assert equal "whitespace " $result
  ti
end_describe

describe lt?
  it "returns true for a lesser string comparison"
    lt? a b
    assert equal 0 $?
  ti

  it "returns false for an equal string comparison"
    ! lt? a a
    assert equal 0 $?
  ti

  it "returns false for a greater string comparison"
    ! lt? b a
    assert equal 0 $?
  ti
end_describe

describe next
  it "increments a letter"
    next result abcd
    assert equal abce $result
  ti

  it "increments a number"
    next result THX1138
    assert equal THX1139 $result
  ti

  it "skips non-alnums"
    next result '<<koala>>'
    assert equal '<<koalb>>' $result
  ti

  it "carries on lowercase letters and numbers"
    next result 1999zzz
    assert equal 2000aaa $result
  ti

  it "carries on uppercase letters and numbers"
    next result ZZZ9999
    assert equal AAAA0000 $result
  ti
end_describe

describe ord
  it "returns the ordinal of a one-character string"
    ord result a
    assert equal 97 $result
  ti
end_describe

describe partition
  it "partitions a string into an array"
    partition results "Spam eggs spam spam and ham" spam
    expecteds=( "Spam eggs " spam " spam and ham" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe present?
  it "is false if no argument"
    ! present?
    assert equal 0 $?
  ti

  it "is false if the argument is empty"
    ! present? ''
    assert equal 0 $?
  ti

  it "is false if the argument is whitespace"
    ! present? $' \t\n'
    assert equal 0 $?
  ti

  it "is true if the argument is non-empty"
    present? a
    assert equal 0 $?
  ti
end_describe

describe reverse
  it "reverses a string"
    reverse result stressed
    assert equal desserts $result
  ti
end_describe

describe right
  it "returns the right side of a string"
    right result hello 2
    assert equal lo $result
  ti
end_describe

describe rindex
  it "returns the index of 'e' in 'hello'"
    rindex result hello e
    assert equal 1 "$result"
  ti

  it "returns the index of 'l' in 'hello'"
    rindex result hello l
    assert equal 3 "$result"
  ti

  it "doesn't return the index of 'a' in 'hello'"
    rindex result hello a
    assert equal '' "$result"
  ti
end_describe

describe rjust
  it "returns the string if the pad is shorter"
    rjust result hello 4
    assert equal hello $result
  ti

  it "returns a padded string"
    rjust result hello 20
    assert equal '               hello' $result
  ti

  it "returns a given pad"
    rjust result hello 20 1234
    assert equal 123412341234123hello $result
  ti
end_describe

describe rpartition
  it "partitions a string into an array"
    rpartition results "Spam eggs spam spam and ham" spam
    expecteds=( "Spam eggs spam " spam " and ham" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe rstrip
  it "strips whitespace from the right of a string"
    rstrip result " whitespace "
    assert equal " whitespace" $result
  ti
end_describe

describe scan
  it "scans by word"
    scan results "cruel world" /[[:alnum:]_]+/
    expecteds=( cruel world )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "scans letters"
    scan results "cruel world" /.../
    expecteds=( cru 'el ' wor )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe slice
  it "returns an indexed character"
    slice result "hello there" 1
    assert equal e $result
  ti

  it "returns an index and length"
    slice result "hello there" 2 3
    assert equal "llo" "$result"
  ti
end_describe

describe split
  it "splits a string into an array"
    split results " now's  the time" ''
    expecteds=( "now's" "the" "time" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "splits a string into an array on space"
    split results " now's  the time" ' '
    expecteds=( "now's" "the" "time" )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "splits on a string"
    split results "mellow yellow" ello
    expecteds=( m "w y" w )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti
end_describe

describe strip
  it "strips whitespace from both sides of a string"
    strip result " whitespace "
    assert equal whitespace $result
  ti
end_describe

describe substr
  it "returns a string based on start and end position"
    substr result hello 2 4
    assert equal ll $result
  ti
end_describe

describe upcase
  it "raises the case of all letters in the string"
    upcase result hEllO
    assert equal HELLO $result
  ti
end_describe
