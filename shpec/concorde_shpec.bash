library=../lib/concorde.bash
source "$library" 2>/dev/null || source "${BASH_SOURCE%/*}/$library"
unset -v library

describe assign
  it "errors if \$2 isn't 'to'"
    $(assign one two three)
    assert unequal $? 0
  end

  it "accepts array literals"; (
    $(assign '( 1 2 )' to '( one two )')
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts a reference for the value array literal"; (
    sample='( 1 2 )'
    $(assign sample to '( one two )')
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts a reference for the destination variable"; (
    sample='( one two )'
    $(assign '( 1 2 )' to sample)
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "makes the last named target an array if there are too many values"; (
    $(assign '( 1 2 3 )' to '( one two )')
    assert equal '1 2 3' "$one ${two[*]}"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end
end

describe bring
  it "errors if \$2 isn't 'from'"
    $(bring one two three)
    assert unequal $? 0
  end

  it "accepts a literal list of functions"; (
    $(grab root from_feature concorde)
    temp=$root/lib/temp.bash
    echo $'one () { :;}\ntwo () { :;}' >"$temp"
    $(bring '( one two )' from "$temp")
    assert equal $'one\ntwo' "$(declare -F one two)"
    rm "$temp"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "accepts a single function argument"; (
    $(grab root from_feature concorde)
    temp=$root/lib/temp.bash
    echo $'one () { :;}' >"$temp"
    $(bring one from "$temp")
    assert equal one "$(declare -F one)"
    rm "$temp"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "brings a function with dependencies"; (
    $(grab root from_feature concorde)
    temp=$root/lib/temp.bash
    get_here_str <<'    EOS'
      declare -Ag __feature_hsh
      __feature_hsh[temp]='( [dependencies]="( two )")'
      one () { :;}
      two () { :;}
    EOS
    echo "$__" >"$temp"
    $(bring one from "$temp")
    assert equal $'one\ntwo' "$(declare -F one two)"
    rm "$temp"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end
end

describe die
  it "exits without an error message"; (
    result=$(die 2>&1)
    assert equal '' "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "exits with a default error code of 1"; (
    (die 2>&1)
    assert equal 1 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "exits with an error message"; (
    result=$(die 'aaaaagh' 2>&1)
    assert equal 'Error: aaaaagh' "$result"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "exits with an error code"; (
    (die '' 2 2>&1)
    assert equal 2 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe feature
  it "creates the __feature_hsh as a global"; (
    while declare -p __feature_hsh >/dev/null 2>&1; do unset -v __feature_hsh; done
    $(feature sample)
    declare -p __feature_hsh >/dev/null 2>&1
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't interfere with an existing feature entry"; (
    $(feature sample)
    $(grab root from_feature concorde)
    assert unequal '' "$root"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a root entry for the feature"; (
    $(feature sample)
    $(grab root from_feature sample)
    assert unequal '' "$root"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "modifies the depth of the root path based on an argument"; (
    $(feature sample)
    $(grab root from_feature sample)
    old_root=$root
    $(feature sample2 depth=2)
    $(grab root from_feature sample2)
    [[ $old_root == $root/* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe grab
  it "instantiates a key/value pair from a hash literal as a local"; (
    $(grab one from '([one]=1)')
    assert equal 1 "$one"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "instantiates more than one key/value pair from a hash literal"; (
    $(grab '(one two)' from '([one]=1 [two]=2)')
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "instantiates all key/value pairs from a hash literal"; (
    $(grab '*' from '([one]=1 [two]=2 [three]=3)')
    assert equal '1 2 3' "$one $two $three"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "instantiates a key/value pair from a hash literal reference"; (
    sample='([one]=1)'
    $(grab one from sample)
    assert equal 1 "$one"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "instantiates more than one key/value pair from a hash literal reference"; (
    sample='([one]=1 [two]=2)'
    $(grab '(one two)' from sample)
    assert equal '1 2' "$one $two"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "instantiates all key/value pairs from a hash literal reference"; (
    sample='([one]=1 [two]=2 [three]=3)'
    $(grab '*' from sample)
    assert equal '1 2 3' "$one $two $three"
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end

  it "errors if \$3 isn't 'from'"; (
    grab one two
    assert unequal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't work if the first argument is a reference"; (
    sample=one
    result=$(grab sample from '([one]=1)')
    declare -p one >/dev/null 2>&1
    assert unequal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures+= $? ))
  end
end

describe local_hsh
  it "creates a local hash"; (
    result=$(local_hsh sample_hsh='( [zero]=0 )')
    [[ $result == *declare* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a literal"; (
    $(local_hsh result_hsh='( [zero]=0 )')
    assert equal 0 "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a succinct literal"; (
    $(local_hsh result_hsh=zero=0)
    assert equal 0 "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a succinct literal with multiple items"; (
    $(local_hsh result_hsh='zero=0 one=1')
    assert equal '0 1' "${result_hsh[zero]} ${result_hsh[one]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a reference to a succinct literal"; (
    sampleh=zero=0
    $(local_hsh result_hsh=sampleh)
    assert equal 0 "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a string reference"; (
    sampleh='( [zero]=0 )'
    $(local_hsh result_hsh=sampleh)
    assert equal 0 "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from an array reference"; (
    sample_ary=( '( [zero]=0 )' )
    $(local_hsh result_hsh=sample_ary[0])
    assert equal 0 "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "creates a hash from a hash reference"; (
    declare -A sample_hsh=( [item]='( [zero]=0 )' )
    $(local_hsh result_hsh=sample_hsh[item])
    assert equal 0 "${result_hsh[zero]}"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe options_parse
  it "accepts a short flag option"; (
    get_here_ary <<'    EOS'
      ( -o '' '' 'a flag' )
    EOS
    $(parse_options __ -o)
    $(grab flag_o from __)
    assert equal 1 "$flag_o"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long flag option"; (
    get_here_ary <<'    EOS'
      ( '' --option '' 'a flag' )
    EOS
    $(parse_options __ --option)
    $(grab flag_option from __ )
    assert equal 1 "$flag_option"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a short argument option"; (
    get_here_ary <<'    EOS'
      ( -o '' argument 'an argument' )
    EOS
    $(parse_options __ -o value )
    $(grab argument from __     )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long argument option without an equals sign"; (
    get_here_ary <<'    EOS'
      ( '' --option argument 'an argument' )
    EOS
    $(parse_options __ --option value )
    $(grab argument from __           )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a long argument option with an equals sign"; (
    get_here_ary <<'    EOS'
      ( '' --option argument 'an argument' )
    EOS
    $(parse_options __ --option=value )
    $(grab argument from __           )
    assert equal value "$argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts multiple short options in one"; (
    get_here_ary  <<'    EOS'
      ( -o '' '' 'a flag' )
      ( -p '' '' 'a flag' )
    EOS
    $(parse_options __ -op            )
    $(grab '( flag_o flag_p )' from __)
    assert equal '1 1' "$flag_o $flag_p"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts multiple short options with the last an argument"; (
    get_here_ary <<'    EOS'
      ( -o '' '' 'a flag' )
      ( -p '' argument 'an argument' )
    EOS
    $(parse_options __ -op value        )
    $(grab '( flag_o argument )' from __)
    assert equal '1 value' "$flag_o $argument"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "accepts a combination of option types"; (
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

  it "outputs arguments"; (
    get_here_ary <<'    EOS'
      ( -o  '' '' 'a flag' )
    EOS
    $(parse_options __ -o arg1 arg2 )
    assert equal 'arg1 arg2' "$1 $2"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't output arguments if none are provided"; (
    get_here_ary <<'    EOS'
      ( -o  '' '' 'a flag' )
    EOS
    $(parse_options __ -o)
    assert equal 0 $#
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

describe part
  it "splits a string on a delimiter"
    part one@two on @
    assert equal '([0]="one" [1]="two")' "$__"
  end

  it "doesn't split a string by name with a delimiter"
    sample=one@two
    part sample on @
    assert equal '([0]="sample")' "$__"
  end
end

describe wed
  it "joins an array literal with a delimiter"
    wed '( one two )' with @
    assert equal one@two "$__"
  end

  it "joins an array literal by name with a delimiter"
    sample='( one two )'
    wed sample with @
    assert equal one@two "$__"
  end
end
