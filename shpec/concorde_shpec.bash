set -o nounset

library=../lib/concorde.bash
source "$library" 2>/dev/null || source "${BASH_SOURCE%/*}/$library"
unset -v library

$(grab '( mktempd rmtree )' fromns concorde.macros)

describe assign
  it "errors if \$2 isn't 'to'"; ( _shpec_failures=0
    $(assign one two three) && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts array literals"; ( _shpec_failures=0
    $(assign '( 1 2 )' to '( one two )')
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts a reference for the value array literal"; ( _shpec_failures=0
    sample='( 1 2 )'
    $(assign sample to '( one two )')
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts a reference for the destination variable"; ( _shpec_failures=0
    sample='( one two )'
    $(assign '( 1 2 )' to sample)
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "makes the last named target an array if there are too many values"; ( _shpec_failures=0
    $(assign '( 1 2 3 )' to '( one two )')
    assert equal '1 2 3' "$one ${two[*]}"
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
    bring '( one two )' from "$temp"
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
    get_here_str <<'    EOS'
      __ns='( [temp]="( [dependencies]=\"( two )\" )" )'
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
    result=$(die 'aaaaagh' 2>&1) ||:
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
    while declare -p __ns >/dev/null 2>&1; do unset -v __ns; done
    $(feature sample)
    declare -p __ns >/dev/null 2>&1
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't interfere with an existing feature entry"; ( _shpec_failures=0
    $(feature sample)
    eval "declare -A ns_hsh=$__ns"
    eval "declare -A concorde_hsh=${ns_hsh[concorde]}"
    [[ -n ${concorde_hsh[root]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a root entry for the feature"; ( _shpec_failures=0
    $(feature sample)
    eval "declare -A ns_hsh=$__ns"
    eval "declare -A sample_hsh=${ns_hsh[sample]}"
    [[ -n ${sample_hsh[root]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "modifies the depth of the root path based on an argument"; ( _shpec_failures=0
    $(feature sample)
    eval "declare -A ns_hsh=$__ns"
    eval "declare -A sample_hsh=${ns_hsh[sample]}"
    $(feature sample2 depth=2)
    eval "declare -A ns_hsh=$__ns"
    eval "declare -A sample2_hsh=${ns_hsh[sample2]}"
    [[ ${sample_hsh[root]} == ${sample2_hsh[root]}/* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't reload"; ( _shpec_failures=0
    $(feature sample)
    result=$($(feature sample); echo hello)
    assert equal '' "$result"
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
    result=$(grab sample from '( [one]=1 )')
    declare -p one >/dev/null 2>&1 && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates a key/value pair from a hash literal as a local"; ( _shpec_failures=0
    $(grab one from '( [one]=1 )')
    assert equal 1 "$one"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates more than one key/value pair from a hash literal"; ( _shpec_failures=0
    $(grab '( one two )' from '( [one]=1 [two]=2 )')
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates all key/value pairs from a hash literal"; ( _shpec_failures=0
    $(grab '*' from '( [one]=1 [two]=2 [three]=3 )')
    assert equal '1 2 3' "$one $two $three"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates a key/value pair from a hash literal reference"; ( _shpec_failures=0
    sample='( [one]=1 )'
    $(grab one from sample)
    assert equal 1 "$one"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates more than one key/value pair from a hash literal reference"; ( _shpec_failures=0
    sample='( [one]=1 [two]=2 )'
    $(grab '( one two )' from sample)
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "instantiates all key/value pairs from a hash literal reference"; ( _shpec_failures=0
    sample='( [one]=1 [two]=2 [three]=3 )'
    $(grab '*' from sample)
    assert equal '1 2 3' "$one $two $three"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "generates nothing if given '*' on an empty hash"; ( _shpec_failures=0
    result=$(grab '*' from '()')
    assert equal 0 "$?$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't set the variable if not in the hash and the variable is set locally"; ( _shpec_failures=0
    declare sample=example
    $(grab sample from '()')
    assert equal example "$sample"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates the variable if not in the hash and the variable is not set locally"; ( _shpec_failures=0
    declare sample=''
    unset -v sample
    $(grab sample from '()')
    is_set sample
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't set the variable if the hash doesn't exist and the variable is set locally"; ( _shpec_failures=0
    declare sample=example
    $(grab sample from '')
    assert equal example "$sample"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates the variable the hash doesn't exist and the variable is not set locally"; ( _shpec_failures=0
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
    assert equal '0 1 2' "$zero $one"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs from a nested hash"; ( _shpec_failures=0
    sample='( [one]="( [two]=2 )" )'
    $(grab two from sample.one)
    assert equal 2 "$two"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs from a double nested hash"; ( _shpec_failures=0
    sample='( [one]="( [two]=\"( [three]=3 )\" )" )'
    $(grab three from sample.one.two)
    assert equal 3 "$three"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "allows names without parentheses"; ( _shpec_failures=0
    sample='( [zero]=0 [one]=1 [two]=2 )'
    $(grab 'zero one two' from sample)
    assert equal '0 1 2' "$zero $one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "grabs from a namespace if the second argument is fromns"; ( _shpec_failures=0
    $(grab root fromns concorde)
    [[ -n $root ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe in_scope
  it "doesn't set a global"; ( _shpec_failures=0
    sample_func () { local sample=one; $(in_scope sample) ;}
    ! is_set sample
    assert equal 0 $?
    return "$_shpec_failures"); : $(( _shpec_failures += $? ))
  end

  it "doesn't change a global"; ( _shpec_failures=0
    declare -g sample=blah
    [[ $sample == 'blah' ]]
    sample_func () { local sample=one; $(in_scope sample) ;}
    sample_func
    assert equal blah "$sample"
    return "$_shpec_failures"); : $(( _shpec_failures += $? ))
  end

  it "returns true if the variable is a local and there is a global"; ( _shpec_failures=0
    declare -g sample=blah
    [[ $sample == 'blah' ]]
    sample_func () { local sample=one; $(in_scope sample) ;}
    sample_func
    assert equal 0 $?
    return "$_shpec_failures"); : $(( _shpec_failures += $? ))
  end

  it "returns false if the variable is not a local and there is a global"; ( _shpec_failures=0
    declare -g sample=blah
    [[ $sample == 'blah' ]]
    sample_func () { $(in_scope sample) ;}
    sample_func && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures"); : $(( _shpec_failures += $? ))
  end

  it "returns true if the variable is a local and there is no global"; ( _shpec_failures=0
    ! is_set sample
    sample_func () { local sample=one; $(in_scope sample) ;}
    sample_func
    assert equal 0 $?
    return "$_shpec_failures"); : $(( _shpec_failures += $? ))
  end

  it "returns false if the variable is not a local and there is no global"; ( _shpec_failures=0
    ! is_set sample
    sample_func () { $(in_scope sample) ;}
    sample_func && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures"); : $(( _shpec_failures += $? ))
  end

  it "returns true if the variable is a global and executed in global scope"; ( _shpec_failures=0
    get_here_str <<'    EOS'
      source concorde.bash
      ! is_set sample
      sample=one
      $(in_scope sample)
    EOS
    bash -c "$__"
    assert equal 0 $?
    return "$_shpec_failures"); : $(( _shpec_failures += $? ))
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
  it "creates a local array"; ( _shpec_failures=0
    result=$(local_ary sample_ary='( zero )')
    [[ $result == *declare* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a literal"; ( _shpec_failures=0
    $(local_ary result_ary='( zero )')
    assert equal zero "${result_ary[0]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a string reference"; ( _shpec_failures=0
    samples='( zero )'
    $(local_ary result_ary=samples)
    assert equal zero "${result_ary[0]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from an array reference"; ( _shpec_failures=0
    sample_ary=( '( zero )' )
    $(local_ary result_ary=sample_ary[0])
    assert equal zero "${result_ary[0]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an array from a hash reference"; ( _shpec_failures=0
    declare -A sample_hsh=( [item]='( zero )' )
    $(local_ary result_ary=sample_hsh[item])
    assert equal zero "${result_ary[0]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe local_hsh
  it "creates an empty hash from an empty literal"; ( _shpec_failures=0
    $(local_hsh result_hsh='()')
    declare -p result_hsh >/dev/null 2>&1
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates an empty hash from an empty string"; ( _shpec_failures=0
    $(local_hsh result_hsh='')
    declare -p result_hsh >/dev/null 2>&1
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a literal"; ( _shpec_failures=0
    $(local_hsh result_hsh='( [zero]="0 1" )')
    assert equal '0 1' "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a string reference"; ( _shpec_failures=0
    sampleh='( [zero]="0 1" )'
    $(local_hsh result_hsh=sampleh)
    assert equal '0 1' "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from an array reference"; ( _shpec_failures=0
    sample_ary=( '( [zero]="0 1" )' )
    $(local_hsh result_hsh=sample_ary[0])
    assert equal '0 1' "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a hash reference"; ( _shpec_failures=0
    declare -A sample_hsh=( [item]='( [zero]="0 1" )' )
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
    sample='( [one]="( [two]=2 )" )'
    $(local_hsh result_hsh=sample.one)
    assert equal 2 "${result_hsh[two]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a two-level nested hash literal"; ( _shpec_failures=0
    sample='( [one]="( [two]=\"( [three]=3 )\" )" )'
    $(local_hsh result_hsh=sample.one.two)
    assert equal 3 "${result_hsh[three]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "works with values that contain a dot"; ( _shpec_failures=0
    $(local_hsh result_hsh='( [zero]=0.0 )')
    assert equal 0.0 "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe macros
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
end

describe __ns
  it "is set"; ( _shpec_failures=0
    declare -p __ns >/dev/null 2>&1
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "is a hash literal"; ( _shpec_failures=0
    [[ $__ns == '('*')' ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "has a concorde key"; ( _shpec_failures=0
    declare -A ns_hsh=$__ns
    [[ -n ${ns_hsh[concorde]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "has a root for the concorde feature"; ( _shpec_failures=0
    declare -A ns_hsh=$__ns
    declare -A concorde_hsh=${ns_hsh[concorde]}
    [[ -n ${concorde_hsh[root]} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "has a concorde.macros key"; ( _shpec_failures=0
    declare -A ns_hsh=$__ns
    declare -A concorde_hsh=${ns_hsh[concorde]}
    [[ -n ${concorde_hsh[macros]} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "has a concorde readlink macro"; ( _shpec_failures=0
    declare -A ns_hsh=$__ns
    declare -A concorde_hsh=${ns_hsh[concorde]}
    declare -A macros_hsh=${concorde_hsh[macros]}
    [[ -n ${macros_hsh[readlink]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end
end

describe options_parse
  it "accepts a short flag option"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( -o '' '' 'a flag' )
    EOS
    $(parse_options __ -o)
    $(grab flag_o from __)
    assert equal 1 "$flag_o"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long flag option"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( '' --option '' 'a flag' )
    EOS
    $(parse_options __ --option)
    $(grab flag_option from __ )
    assert equal 1 "$flag_option"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a short argument option"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( -o '' argument 'an argument' )
    EOS
    $(parse_options __ -o value )
    $(grab argument from __     )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long argument option without an equals sign"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( '' --option argument 'an argument' )
    EOS
    $(parse_options __ --option value )
    $(grab argument from __           )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long argument option with an equals sign"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( '' --option argument 'an argument' )
    EOS
    $(parse_options __ --option=value )
    $(grab argument from __           )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts multiple short options in one"; ( _shpec_failures=0
    get_here_ary  <<'    EOS'
      ( -o '' '' 'a flag' )
      ( -p '' '' 'a flag' )
    EOS
    $(parse_options __ -op            )
    $(grab '( flag_o flag_p )' from __)
    assert equal '1 1' "$flag_o $flag_p"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts multiple short options with the last an argument"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( -o '' '' 'a flag' )
      ( -p '' argument 'an argument' )
    EOS
    $(parse_options __ -op value        )
    $(grab '( flag_o argument )' from __)
    assert equal '1 value' "$flag_o $argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a combination of option types"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( ''  --option1 ''        'flag 1'      )
      ( -o  ''        ''        'flag 2'      )
      ( ''  --option3 argument3 'argument 3'  )
      ( -p  ''        argument4 'argument 4'  )
      ( -q  --option5 ''        'flag 5'      )
      ( -r  --option6 argument6 'argument 6'  )
    EOS
    $(parse_options __ --option1 -o --option3=value3 -p value4 --option5 -r value6)
    $(grab '(
      flag_option1
      flag_o
      argument3
      argument4
      flag_option5
      argument6
    )' from __ )
    assert equal '1 1 value3 value4 1 value6' "$flag_option1 $flag_o $argument3 $argument4 $flag_option5 $argument6"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "outputs arguments"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( -o  '' '' 'a flag' )
    EOS
    $(parse_options __ -o arg1 arg2 )
    assert equal 'arg1 arg2' "$1 $2"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't output arguments if none are provided"; ( _shpec_failures=0
    get_here_ary <<'    EOS'
      ( -o  '' '' 'a flag' )
    EOS
    $(parse_options __ -o)
    assert equal 0 $#
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe part
  it "splits a string on a delimiter"; ( _shpec_failures=0
    part one@two on @
    assert equal '([0]="one" [1]="two")' "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't split a string by name with a delimiter"; ( _shpec_failures=0
    sample=one@two
    part sample on @
    assert equal '([0]="sample")' "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe stuff
  it "inserts a local variable as a key into an empty hash literal"; ( _shpec_failures=0
    sample=one
    stuff sample into '()'
    eval "declare -A result_hsh=$__"
    assert equal one "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts a local variable as a key into an empty string"; ( _shpec_failures=0
    sample=one
    stuff sample into ''
    eval "declare -A result_hsh=$__"
    assert equal one "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts a local variable as a key into a reference to an empty hash literal"; ( _shpec_failures=0
    sample=one
    example='()'
    stuff sample into example
    eval "declare -A result_hsh=$__"
    assert equal one "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts a local variable as a key into a reference to an empty string"; ( _shpec_failures=0
    sample=one
    example=''
    stuff sample into example
    eval "declare -A result_hsh=$__"
    assert equal one "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts multiple local variables as keys into an empty hash literal"; ( _shpec_failures=0
    zero=0
    one=1
    stuff '( zero one )' into '()'
    eval "declare -A result_hsh=$__"
    assert equal '0 1' "${result_hsh[zero]} ${result_hsh[one]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts multiple local variables as keys into an empty string"; ( _shpec_failures=0
    zero=0
    one=1
    stuff '( zero one )' into ''
    eval "declare -A result_hsh=$__"
    assert equal '0 1' "${result_hsh[zero]} ${result_hsh[one]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts multiple local variables as keys into a reference to an empty hash literal"; ( _shpec_failures=0
    zero=0
    one=1
    example='()'
    stuff '( zero one )' into example
    eval "declare -A result_hsh=$__"
    assert equal '0 1' "${result_hsh[zero]} ${result_hsh[one]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts multiple local variables as keys into a reference to an empty string"; ( _shpec_failures=0
    zero=0
    one=1
    example=''
    stuff '( zero one )' into example
    eval "declare -A result_hsh=$__"
    assert equal '0 1' "${result_hsh[zero]} ${result_hsh[one]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts a local variable as a key into a nested hash literal"; ( _shpec_failures=0
    sample=example
    sampleh='( [zero]="( [one]=1 )" )'
    stuff sample into sampleh.zero
    eval "declare -A result_hsh=$__"
    assert equal example "${result_hsh[sample]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts a namespace"; ( _shpec_failures=0
    sample=zero
    stuff sample intons
    eval "declare -A ns_hsh=$__ns"
    [[ -n ${ns_hsh[sample]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts into an unset namespace"; ( _shpec_failures=0
    unset -v __ns
    sample=zero
    stuff sample intons
    eval "declare -A ns_hsh=$__ns"
    [[ -n ${ns_hsh[sample]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts into an existing namespace"; ( _shpec_failures=0
    sample=zero
    stuff sample intons concorde
    eval "declare -A ns_hsh=$__ns"
    eval "declare -A concorde_hsh=${ns_hsh[concorde]}"
    [[ -n ${concorde_hsh[sample]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "inserts into a nested namespace"; ( _shpec_failures=0
    sample=zero
    stuff sample intons concorde.macros
    eval "declare -A ns_hsh=$__ns"
    eval "declare -A concorde_hsh=${ns_hsh[concorde]}"
    eval "declare -A macros_hsh=${concorde_hsh[macros]}"
    [[ -n ${macros_hsh[sample]:-} ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe wed
  it "joins an array literal with a delimiter"; ( _shpec_failures=0
    wed '( one two )' with @
    assert equal one@two "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "joins an array literal by name with a delimiter"; ( _shpec_failures=0
    sample='( one two )'
    wed sample with @
    assert equal one@two "$__"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end
