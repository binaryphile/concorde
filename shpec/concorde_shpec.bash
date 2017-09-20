export TMPDIR=$HOME/tmp
mkdir -p "$TMPDIR"

set -o nounset

library=../lib/concorde.bash
source "$library" 2>/dev/null || source "${BASH_SOURCE%/*}/$library"
unset -v library

$(grab 'mktempd rmtree' fromns concorde.macros)

describe assign
  it "errors if \$2 isn't 'to'"; ( _shpec_failures=0
    $(assign one two three) && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts array literals"; ( _shpec_failures=0
    $(assign '1 2' to 'one two')
    assert equal '(1) (2)' "($one) ($two)"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts a reference for the value array literal"; ( _shpec_failures=0
    sample='1 2'
    $(assign sample to 'one two')
    assert equal '(1) (2)' "($one) ($two)"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts a reference for the destination variable"; ( _shpec_failures=0
    sample='one two'
    $(assign '1 2' to sample)
    assert equal '(1) (2)' "($one) ($two)"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "makes the last named target an array if there are too many values"; ( _shpec_failures=0
    $(assign '1 2 3' to 'one two')
    assert equal '(1) (2 3)' "($one) (${two[*]})"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end
end

describe bring
  it "errors if \$2 isn't 'from'"; ( _shpec_failures=0
    bring one two three && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a literal list of functions"; ( _shpec_failures=0
    dir=$($mktempd)
    [[ -d $dir ]] || return
    temp=$dir/temp.bash
    echo $'one () { echo hello ;}\ntwo () { echo world ;}' >"$temp"
    bring 'one two' from "$temp"
    assert equal $'hello\nworld' "$(one; two)"
    $rmtree "$dir"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts a single function argument"; ( _shpec_failures=0
    dir=$($mktempd)
    [[ -d $dir ]] || return
    temp=$dir/temp.bash
    echo $'one () { echo hello ;}' >"$temp"
    bring one from "$temp"
    assert equal hello "$(one)"
    $rmtree "$dir"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "brings a function with dependencies"; ( _shpec_failures=0
    dir=$($mktempd)
    [[ -d $dir ]] || return
    temp=$dir/temp.bash
    get <<'    EOS'
      __ns='[temp]="[dependencies]=\"two\""'
      one () { echo hello; two  ;}
      two () { echo world       ;}
    EOS
    echo "$__" >"$temp"
    bring one from "$temp"
    assert equal $'hello\nworld' "$(one)"
    $rmtree "$dir"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "works with expansions"; ( _shpec_failures=0
    dir=$($mktempd)
    [[ -d $dir ]] || return
    temp=$dir/temp.bash
    echo $'one () { echo "$1" ;}' >"$temp"
    bring one from "$temp"
    assert equal hello "$(one hello)"
    $rmtree "$dir"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end
end

describe die
  it "exits without an error message"; ( _shpec_failures=0
    result=$(die 2>&1) ||:
    assert equal '' "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "exits with a default error code of the last command"; ( _shpec_failures=0
    false
    (die 2>&1) && result=$? || result=$?
    true
    (die 2>&1) && result="$result $?" || result="$result $?"
    assert equal '1 0' "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "exits with an error message"; ( _shpec_failures=0
    result=$(die 'aaaaagh' 1 2>&1) ||:
    assert equal 'Error: aaaaagh' "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "exits with an error code"; ( _shpec_failures=0
    (die '' 2 2>&1) && result=$? || result=$?
    assert equal 2 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe escape_items
  it "creates a quoted string from some items"; ( _shpec_failures=0
    escape_items 'one two' three
    assert equal 'one\ two three' "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe feature
  it "creates namespaces as a global"; ( _shpec_failures=0
    declare __ns=''
    unset -v __ns
    $(feature sample)
    declare -p __ns >/dev/null 2>&1
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't interfere with an existing feature entry"; ( _shpec_failures=0
    $(feature sample)
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A concorde_hsh=( ${ns_hsh[concorde]} )"
    [[ -n ${concorde_hsh[root]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a root entry for the feature"; ( _shpec_failures=0
    $(feature sample)
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A sample_hsh=( ${ns_hsh[sample]} )"
    [[ -n ${sample_hsh[root]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "modifies the depth of the root path based on an argument"; ( _shpec_failures=0
    $(feature sample)
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A sample_hsh=( ${ns_hsh[sample]} )"
    $(feature sample2 depth=2)
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A sample2_hsh=( ${ns_hsh[sample2]} )"
    [[ ${sample_hsh[root]} == ${sample2_hsh[root]}/* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't reload"; ( _shpec_failures=0
    $(feature sample)
    result=$($(feature sample); echo hello)
    assert equal '0 ' "$? $result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "reloads if __reload=1 is set"; ( _shpec_failures=0
    $(feature sample)
    __reload=1
    result=$($(feature sample); echo hello)
    assert equal hello "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe grab
  it "errors if \$2 isn't 'from'"; ( _shpec_failures=0
    grab one two && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't work if the first argument is a reference"; ( _shpec_failures=0
    sample=one
    result=$(grab sample from [one]=1)
    declare -p one >/dev/null 2>&1 && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates a key/value pair from a hash literal as a local"; ( _shpec_failures=0
    $(grab one from [one]=1)
    assert equal 1 "$one"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates more than one key/value pair from a hash literal"; ( _shpec_failures=0
    $(grab 'one two' from '[one]=1 [two]=2')
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates all key/value pairs from a hash literal"; ( _shpec_failures=0
    $(grab '*' from '[one]=1 [two]=2 [three]=3')
    assert equal '1 2 3' "$one $two $three"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates a key/value pair from a hash literal reference"; ( _shpec_failures=0
    sample=[one]=1
    $(grab one from sample)
    assert equal 1 "$one"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates more than one key/value pair from a hash literal reference"; ( _shpec_failures=0
    sample='[one]=1 [two]=2'
    $(grab 'one two' from sample)
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs if the list contains newlines"; ( _shpec_failures=0
    sample='[one]=1 [two]=2'
    $(grab '
      one
      two
    ' from sample)
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates all key/value pairs from a hash literal reference"; ( _shpec_failures=0
    sample='[one]=1 [two]=2 [three]=3'
    $(grab '*' from sample)
    assert equal '1 2 3' "$one $two $three"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "generates nothing if given '*' on an empty hash"; ( _shpec_failures=0
    result=$(grab '*' from '')
    assert equal 0 "$?$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't set the variable if not in the hash and the variable is set locally"; ( _shpec_failures=0
    declare sample=example
    $(grab sample from '')
    assert equal example "$sample"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates the variable if not in the hash and the variable is not set locally"; ( _shpec_failures=0
    declare sample=''
    unset -v sample
    $(grab sample from '')
    is_set sample
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs from keyword arguments"; ( _shpec_failures=0
    $(grab one from zero='0 1' one=2)
    assert equal 2 "$one"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs all keyword arguments"; ( _shpec_failures=0
    $(grab '*' from zero='0 1' one=2)
    assert equal '(0 1) (2)' "($zero) ($one)"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs from a nested hash"; ( _shpec_failures=0
    sample='[one]="[two]=2"'
    $(grab two from sample.one)
    assert equal 2 "$two"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs from a double nested hash"; ( _shpec_failures=0
    sample='[one]="[two]=\"[three]=3\""'
    $(grab three from sample.one.two)
    assert equal 3 "$three"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "allows names without parentheses"; ( _shpec_failures=0
    sample='[zero]=0 [one]=1 [two]=2'
    $(grab 'zero one two' from sample)
    assert equal '(0) (1) (2)' "($zero) ($one) ($two)"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs from a namespace if the second argument is fromns"; ( _shpec_failures=0
    $(grab root fromns concorde)
    [[ -n $root ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe is_set
  it "is false if the variable is not set"; ( _shpec_failures=0
    declare sample=''
    unset -v sample
    is_set sample && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is true if the variable is empty"; ( _shpec_failures=0
    sample=''
    is_set sample
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is true if the variable has a value"; ( _shpec_failures=0
    sample=example
    is_set sample
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is false if the variable is an element of an unset array"; ( _shpec_failures=0
    declare -a sample_ary=()
    unset -v sample_ary
    is_set sample_ary[0] && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is false if the variable is an unset array element"; ( _shpec_failures=0
    declare -a sample_ary=()
    unset -v sample_ary
    sample_ary=()
    is_set sample_ary[0] && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is true if the variable is an empty array element"; ( _shpec_failures=0
    declare -a sample_ary=()
    unset -v sample_ary
    sample_ary=( '' )
    is_set sample_ary[0]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is true if the variable is an array element with a value"; ( _shpec_failures=0
    declare -a sample_ary=()
    unset -v sample_ary
    sample_ary=( 'a value' )
    is_set sample_ary[0]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is false if the variable is an element of an unset hash"; ( _shpec_failures=0
    unset -v sample_hsh
    is_set sample_hsh[index] && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is false if the variable is an unset hash element"; ( _shpec_failures=0
    unset -v sample_hsh
    declare -A sample_hsh=()
    is_set sample_hsh[zero] && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is true if the variable is an empty array element"; ( _shpec_failures=0
    unset -v sample_hsh
    declare -A sample_hsh=( [zero]='' )
    is_set sample_hsh[zero]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "is true if the variable is an array element with a value"; ( _shpec_failures=0
    unset -v sample_hsh
    declare -A sample_hsh=( [zero]=0 )
    is_set sample_hsh[zero]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe local_ary
  it "creates an array from a single item"; ( _shpec_failures=0
    declare sample=''
    unset -v sample
    $(local_ary result_ary=sample)
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(sample)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a reference"; ( _shpec_failures=0
    sample=one
    $(local_ary result_ary=sample)
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a string with multiple items"; ( _shpec_failures=0
    $(local_ary result_ary='one two')
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one) (two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from multiple items"; ( _shpec_failures=0
    $(local_ary result_ary=one two)
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one) (two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a quoted item"; ( _shpec_failures=0
    $(local_ary result_ary='"one two"')
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a reference to a quoted item"; ( _shpec_failures=0
    sample='"one two"'
    $(local_ary result_ary=sample)
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a quoted item with an escaped newline"; ( _shpec_failures=0
    $(local_ary result_ary="\$'one\ntwo'")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal $'(one\ntwo)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from multiple quoted items in a string"; ( _shpec_failures=0
    $(local_ary result_ary='"one two" "three four"')
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two) (three four)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from multiple quoted items"; ( _shpec_failures=0
    $(local_ary result_ary='"one two"' '"three four"')
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two) (three four)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a multiline string"; ( _shpec_failures=0
    $(local_ary result_ary=$'one\ntwo')
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one) (two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a reference to a multiline string"; ( _shpec_failures=0
    sample=$'one\ntwo'
    $(local_ary result_ary=sample)
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one) (two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe local_hsh
  it "creates an empty hash from an empty literal"; ( _shpec_failures=0
    $(local_hsh result_hsh='')
    declare -p result_hsh >/dev/null 2>&1
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a literal"; ( _shpec_failures=0
    $(local_hsh result_hsh='[zero]="0 1"')
    assert equal '0 1' "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a string reference"; ( _shpec_failures=0
    sampleh='[zero]="0 1"'
    $(local_hsh result_hsh=sampleh)
    assert equal '0 1' "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from an array reference"; ( _shpec_failures=0
    sample_ary=( '[zero]="0 1"' )
    $(local_hsh result_hsh=sample_ary[0])
    assert equal '0 1' "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a hash reference"; ( _shpec_failures=0
    declare -A sample_hsh=( [item]='[zero]="0 1"' )
    $(local_hsh result_hsh=sample_hsh[item])
    assert equal '0 1' "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a keyword argument"; ( _shpec_failures=0
    $(local_hsh result_hsh=zero="0 1")
    assert equal '0 1' "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from multiple keyword arguments"; ( _shpec_failures=0
    $(local_hsh result_hsh=zero="0 1" one=2)
    assert equal '0 1 2' "${result_hsh[zero]} ${result_hsh[one]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a nested hash literal"; ( _shpec_failures=0
    sample='[one]="[two]=2"'
    $(local_hsh result_hsh=sample.one)
    assert equal 2 "${result_hsh[two]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a two-level nested hash literal"; ( _shpec_failures=0
    sample='[one]="[two]=\"[three]=3\""'
    $(local_hsh result_hsh=sample.one.two)
    assert equal 3 "${result_hsh[three]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "works with values which contain a dot"; ( _shpec_failures=0
    $(local_hsh result_hsh=[zero]=0.0)
    assert equal 0.0 "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe local_nry
  it "creates a multidimensional array from a multiline string"; ( _shpec_failures=0
    $(local_nry result_ary=$'one two\nthree')
    $(local_ary result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one) (two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a multidimensional array from a string with a quoted item"; ( _shpec_failures=0
    $(local_nry result_ary=$'"one two"\nthree')
    $(local_ary result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a multidimensional array from a string with a quoted item with an escaped newline"; ( _shpec_failures=0
    $(local_nry result_ary="\$'one\ntwo'"$'\nthree')
    $(local_ary result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal $'(one\ntwo)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a multidimensional array from multiple quoted items with a newline in a string"; ( _shpec_failures=0
    $(local_nry result_ary=$'"one two" "three four"\nfive')
    $(local_ary result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two) (three four)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a multidimensional array from multiple quoted items with a newline"; ( _shpec_failures=0
    $(local_nry result_ary='"one two"' $'"three four"\nfive')
    $(local_ary result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two) (three four)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from the second multiple quoted items in a string"; ( _shpec_failures=0
    $(local_nry result_ary=$'"one two" "three four"\n"five six" "seven eight"')
    $(local_ary result_ary="${result_ary[1]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(five six) (seven eight)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from the second multiple quoted items"; ( _shpec_failures=0
    $(local_nry result_ary='"one two"' $'"three four"\n"five six"' '"seven eight"')
    $(local_ary result_ary="${result_ary[1]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(five six) (seven eight)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from the second multiple quoted items in a reference to a string"; ( _shpec_failures=0
    sample=$'"one two" "three four"\n"five six" "seven eight"'
    $(local_nry result_ary=sample)
    $(local_ary result_ary="${result_ary[1]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(five six) (seven eight)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe macros
  it "includes cptree"; ( _shpec_failures=0
    $(grab cptree fromns concorde.macros)
    [[ $cptree == cp* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes install"; ( _shpec_failures=0
    $(grab install fromns concorde.macros)
    [[ $install == install* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes installd"; ( _shpec_failures=0
    $(grab installd fromns concorde.macros)
    [[ $installd == install* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes installx"; ( _shpec_failures=0
    $(grab installx fromns concorde.macros)
    [[ $installx == install* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes mkdir"; ( _shpec_failures=0
    $(grab mkdir fromns concorde.macros)
    [[ $mkdir == mkdir* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes mktemp"; ( _shpec_failures=0
    $(grab mktemp fromns concorde.macros)
    [[ $mktemp == mktemp* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes mktempd"; ( _shpec_failures=0
    $(grab mktempd fromns concorde.macros)
    [[ $mktempd == mktemp* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes rm"; ( _shpec_failures=0
    $(grab rm fromns concorde.macros)
    [[ $rm == rm* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes rmdir"; ( _shpec_failures=0
    $(grab rmdir fromns concorde.macros)
    [[ $rmdir == rmdir* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes rmtree"; ( _shpec_failures=0
    $(grab rmtree fromns concorde.macros)
    [[ $rmtree == rm* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "includes sed"; ( _shpec_failures=0
    $(grab sed fromns concorde.macros)
    [[ $sed == sed* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe member_of
  it "identifies a member of an array literal"; ( _shpec_failures=0
    sample_ary=( one two )
    repr sample_ary
    member_of "$__" one
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't identify a non-member of an array literal"; ( _shpec_failures=0
    sample_ary=( one two )
    repr sample_ary
    member_of "$__" three
    assert unequal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "identifies a member of a reference to an array literal"; ( _shpec_failures=0
    sample_ary=( one two )
    repr sample_ary
    member_of __ one
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't identify a non-member of a reference to an array literal"; ( _shpec_failures=0
    sample_ary=( one two )
    repr sample_ary
    member_of __ three
    assert unequal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "identifies a member of set of args"; ( _shpec_failures=0
    member_of one two one
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't identify a non-member of a set of args"; ( _shpec_failures=0
    member_of one two three
    assert unequal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "identifies a member of set of args with a space"; ( _shpec_failures=0
    member_of '"one two"' three 'one two'
    rc=$?
    assert equal 0 $rc
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "identifies a member of set of args with a newline"; ( _shpec_failures=0
    member_of "\$'one\ntwo'" three $'one\ntwo'
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe __ns
  it "is set"; ( _shpec_failures=0
    declare -p __ns >/dev/null 2>&1
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "is a hash literal"; ( _shpec_failures=0
    [[ $__ns == '['* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "has a concorde key"; ( _shpec_failures=0
    eval "declare -A ns_hsh=( $__ns )"
    [[ -n ${ns_hsh[concorde]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "has a root for the concorde feature"; ( _shpec_failures=0
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A concorde_hsh=( ${ns_hsh[concorde]} )"
    [[ -n ${concorde_hsh[root]} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "has a concorde.macros key"; ( _shpec_failures=0
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A concorde_hsh=( ${ns_hsh[concorde]} )"
    [[ -n ${concorde_hsh[macros]} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "has a concorde readlink macro"; ( _shpec_failures=0
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A concorde_hsh=( ${ns_hsh[concorde]} )"
    eval "declare -A macros_hsh=( ${concorde_hsh[macros]} )"
    [[ -n ${macros_hsh[readlink]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end
end

describe parse_options
  it "accepts no options on the command line when options are defined"; ( _shpec_failures=0
    get <<'    EOS'
      -o '' '' 'a flag'
    EOS
    $(parse_options __)
    assert equal '' "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a short flag option"; ( _shpec_failures=0
    get <<'    EOS'
      -o '' '' 'a flag'
    EOS
    $(parse_options __ -o)
    $(grab o_flag from __)
    assert equal 1 "$o_flag"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long flag option"; ( _shpec_failures=0
    get <<'    EOS'
      '' --option '' 'a flag'
    EOS
    $(parse_options __ --option)
    $(grab option_flag from __ )
    assert equal 1 "$option_flag"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a short argument option"; ( _shpec_failures=0
    get <<'    EOS'
      -o '' argument 'an argument'
    EOS
    $(parse_options __ -o value )
    $(grab argument from __     )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long argument option without an equals sign"; ( _shpec_failures=0
    get <<'    EOS'
      '' --option argument 'an argument'
    EOS
    $(parse_options __ --option value )
    $(grab argument from __           )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long argument option with an equals sign"; ( _shpec_failures=0
    get <<'    EOS'
      '' --option argument 'an argument'
    EOS
    $(parse_options __ --option=value )
    $(grab argument from __           )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts multiple short options in one"; ( _shpec_failures=0
    get <<'    EOS'
      -o '' '' 'a flag'
      -p '' '' 'a flag'
    EOS
    $(parse_options __ -op            )
    $(grab 'o_flag p_flag' from __)
    assert equal '1 1' "$o_flag $p_flag"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts multiple short options with the last an argument"; ( _shpec_failures=0
    get <<'    EOS'
      -o '' '' 'a flag'
      -p '' argument 'an argument'
    EOS
    $(parse_options __ -op value        )
    $(grab 'o_flag argument' from __)
    assert equal '1 value' "$o_flag $argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a combination of option types"; ( _shpec_failures=0
    get <<'    EOS'
      ''  --option1 ''        'flag 1'
      -o  ''        ''        'flag 2'
      ''  --option3 argument3 'argument 3'
      -p  ''        argument4 'argument 4'
      -q  --option5 ''        'flag 5'
      -r  --option6 argument6 'argument 6'
    EOS
    $(parse_options __ --option1 -o --option3=value3 -p value4 --option5 -r value6)
    $(grab '
      option1_flag
      o_flag
      argument3
      argument4
      option5_flag
      argument6
    ' from __ )
    assert equal '1 1 value3 value4 1 value6' "$option1_flag $o_flag $argument3 $argument4 $option5_flag $argument6"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "outputs arguments"; ( _shpec_failures=0
    get <<'    EOS'
      -o  '' '' 'a flag'
    EOS
    $(parse_options __ -o arg1 arg2 )
    assert equal 'arg1 arg2' "$1 $2"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't output arguments if none are provided"; ( _shpec_failures=0
    get <<'    EOS'
      -o  '' '' 'a flag'
    EOS
    $(parse_options __ -o)
    assert equal 0 $#
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe part
  it "splits a string on a delimiter"; ( _shpec_failures=0
    part one@two on @
    assert equal 'one two' "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't split a string by name with a delimiter"; ( _shpec_failures=0
    sample=one@two
    part sample on @
    assert equal sample "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe repr
  it "generates a representation of an empty array"; ( _shpec_failures=0
    sample_ary=()
    repr sample_ary
    eval "declare -a result_ary=( $__ )"
    assert equal 0 "${#result_ary[@]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "generates a representation of an array"; ( _shpec_failures=0
    sample_ary=( zero one )
    repr sample_ary
    eval "declare -a result_ary=( $__ )"
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(zero) (one)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "generates a representation of an array with a space in an item"; ( _shpec_failures=0
    sample_ary=( "zero one" two )
    repr sample_ary
    eval "declare -a result_ary=( $__ )"
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(zero one) (two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "generates a representation of an array with a newline in an item"; ( _shpec_failures=0
    sample_ary=( $'zero\none' two )
    repr sample_ary
    eval "declare -a result_ary=( $__ )"
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal $'(zero\none) (two)' "${result% }"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "generates a representation of an empty hash"; ( _shpec_failures=0
    declare -A sample_hsh=()
    repr sample_hsh
    eval "declare -A result_hsh=( $__ )"
    assert equal 0 "${#result_hsh[@]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "generates a representation of a nested hash variable"; ( _shpec_failures=0
    declare -A sample_hsh=( [zero]=0 [one]="[two]=2 [three]=3" )
    repr sample_hsh
    eval "declare -A example_hsh=( $__ )"
    eval "declare -A result_hsh=( ${example_hsh[one]} )"
    for item in $(IFS=$'\n'; sort <<<"${!result_hsh[*]}"); do
      result_ary+=( "(${result_hsh[$item]})" )
    done
    assert equal '(3) (2)' "${result_ary[*]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "generates a representation of a nested hash variable with newlines"; ( _shpec_failures=0
    declare -A sample_hsh=( [zero]=0 [one]="[two]=$'2\n3' [four]=4" )
    repr sample_hsh
    eval "declare -A example_hsh=( $__ )"
    eval "declare -A result_hsh=( ${example_hsh[one]} )"
    for item in $(IFS=$'\n'; sort <<<"${!result_hsh[*]}"); do
      result_ary+=( "(${result_hsh[$item]})" )
    done
    assert equal $'(4) (2\n3)' "${result_ary[*]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe stuff
  it "inserts a local variable as a key into an empty hash literal"; ( _shpec_failures=0
    sample=one
    stuff sample into ''
    eval "declare -A result_hsh=( $__ )"
    assert equal one "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts a local variable as a key into a reference to an empty string"; ( _shpec_failures=0
    sample=one
    example=''
    stuff sample into example
    eval "declare -A result_hsh=( $__ )"
    assert equal one "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts multiple local variables as keys into an empty string"; ( _shpec_failures=0
    zero=0
    one=1
    stuff 'zero one' into ''
    eval "declare -A result_hsh=( $__ )"
    for item in $(IFS=$'\n'; sort <<<"${!result_hsh[*]}"); do
      result_ary+=( "(${result_hsh[$item]})" )
    done
    assert equal '(1) (0)' "${result_ary[*]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts multiple local variables as keys into a reference to an empty string"; ( _shpec_failures=0
    zero=0
    one=1
    example=''
    stuff 'zero one' into example
    eval "declare -A result_hsh=( $__ )"
    for item in $(IFS=$'\n'; sort <<<"${!result_hsh[*]}"); do
      result_ary+=( "(${result_hsh[$item]})" )
    done
    assert equal '(1) (0)' "${result_ary[*]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts a local variable as a key into a nested hash literal"; ( _shpec_failures=0
    sample=example
    sampleh='[zero]="[one]=1"'
    stuff sample into sampleh.zero
    eval "declare -A result_hsh=( $__ )"
    for item in $(IFS=$'\n'; sort <<<"${!result_hsh[*]}"); do
      result_ary+=( "(${result_hsh[$item]})" )
    done
    assert equal '(1) (example)' "${result_ary[*]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts a namespace"; ( _shpec_failures=0
    sample=zero
    stuff sample intons
    eval "declare -A result_hsh=( $__ns )"
    assert equal zero "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts into an unset namespace"; ( _shpec_failures=0
    declare __ns=''
    unset -v __ns
    sample=zero
    stuff sample intons
    eval "declare -A result_hsh=( $__ns )"
    assert equal zero "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts into an existing namespace"; ( _shpec_failures=0
    sample=zero
    stuff sample intons concorde
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A concorde_hsh=( ${ns_hsh[concorde]} )"
    assert equal zero "${concorde_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts into a nested namespace"; ( _shpec_failures=0
    sample=zero
    stuff sample intons concorde.macros
    eval "declare -A ns_hsh=( $__ns )"
    eval "declare -A concorde_hsh=( ${ns_hsh[concorde]} )"
    eval "declare -A macros_hsh=( ${concorde_hsh[macros]} )"
    assert equal zero "${macros_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe wed
  it "joins an array literal with a delimiter"; ( _shpec_failures=0
    wed 'one two' with @
    assert equal one@two "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "joins an array literal by name with a delimiter"; ( _shpec_failures=0
    sample='one two'
    wed sample with @
    assert equal one@two "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end
