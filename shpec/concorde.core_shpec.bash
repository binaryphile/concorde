IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/concorde.core.bash

export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir -p $TMPDIR

describe alias_retvar
  alias_retvar result

  it "returns a named variable"
    samplef () {
      local result=$1
      local sample

      sample=value
      result = sample && return
    }
    samplef result
    assert equal value $result
  ti

  unalias result
end_describe

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

  unalias sample
end_describe

describe array
  it "creates an array declaration"
    samples=( zero one two )
    $(array results=samples)
    assert equal "${samples[*]}" "${results[*]}"
  ti

  it "creates a hash declaration"
    samples=( zero one two )
    $(array results=samples)
    assert equal "${samples[*]}" "${results[*]}"
  ti

  it "creates two array declarations"
    samples=( zero one two )
    more=( three four five )
    $(array results=samples other=more)
    expecteds=(
      'results=([0]="zero" [1]="one" [2]="two")'
      'other=([0]="three" [1]="four" [2]="five")'
    )
    assert equal "${samples[*]}${more[*]}" "${results[*]}${other[*]}"
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

describe emit
  it "runs a command"
    result=$($(emit <<<$'echo hello\necho there'))
    assert equal $'hello\nthere' "$result"
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

describe gsub
  it "substitutes all occurrences of a pattern"
    gsub result hello [aeiou] *
    assert equal h*ll* $result
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

describe return_
  it "assigns a value from a named variable in another named variable"
    sample=text
    return_ result sample
    assert equal text $result
  ti

  it "doesn't let a local mask the return"
    declare result
    foo () {
      local result=''
      local sample=text

      local $1 && return_ $1 sample
    }
    foo result
    assert equal text $result
  ti

  it "returns an array"
    declare results=()
    foo () {
      local results=()
      local samples=( one two three )

      local $1 && return_ $1 samples
    }
    foo results
    expecteds=( one two three )
    assert equal "${expecteds[*]}" "${results[*]}"
  ti

  it "returns a hash"
    declare -A results=()
    foo () {
      local -A results=()
      local -A samples=( [one]=1 [two]=2 [three]=3 )

      local $1 && return_ $1 samples
    }
    foo results
    assert equal "declare -A results='([one]=\"1\" [two]=\"2\" [three]=\"3\" )'" $(declare -p results)
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
