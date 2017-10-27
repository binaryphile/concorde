export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir --parents -- "$TMPDIR"

set -o nounset

source "$(dirname -- "$(readlink --canonicalize -- "$BASH_SOURCE")")"/../lib/concorde.bash

describe concorde.array
  it "creates an empty array from an empty literal"; ( _shpec_failures=0
    $(concorde.array result_ary='')
    declare -p result_ary >/dev/null
    assert equal '(0) (0)' "($?) (${#result_ary[@]})"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "creates an array from a literal"; ( _shpec_failures=0
    $(concorde.array result_ary='"0 1" "2 3"')
    assert equal '(0 1) (2 3)' "(${result_ary[0]}) (${result_ary[1]})"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.assign
  it "errors if the second argument isn't 'to'"; ( _shpec_failures=0
    $(concorde.assign one two three)
    assert equal '(113) (1) (ArgumentError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures+= $? ))
  end

  it "accepts array literals"; ( _shpec_failures=0
    $(concorde.assign '1 2' to 'one two')
    assert equal '(1) (2)' "($one) ($two)"
    return "$_shpec_failures" );: $(( _shpec_failures+= $? ))
  end

  it "makes the last named target an array if there are too many values"; ( _shpec_failures=0
    $(concorde.assign '1 2 3' to 'one two')
    assert equal '(1) (2 3)' "($one) (${two[*]})"
    return "$_shpec_failures" );: $(( _shpec_failures+= $? ))
  end
end

describe concorde.defined
  it "is false if the variable is not set"; ( _shpec_failures=0
    sample=''
    unset -v sample
    concorde.defined sample && result=$? || result=$?
    assert unequal 0 "$result"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is true if the variable is empty"; ( _shpec_failures=0
    sample=''
    concorde.defined sample
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is true if the variable has a value"; ( _shpec_failures=0
    sample=example
    concorde.defined sample
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is false if the variable is an element of an unset array"; ( _shpec_failures=0
    declare -a sample_ary=()
    unset -v sample_ary
    concorde.defined sample_ary[0]
    assert unequal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is false if the variable is an unset array element"; ( _shpec_failures=0
    declare -a sample_ary=()
    unset -v sample_ary
    sample_ary=()
    concorde.defined sample_ary[0]
    assert unequal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is true if the variable is an empty array element"; ( _shpec_failures=0
    declare -a sample_ary=()
    unset -v sample_ary
    sample_ary=( '' )
    concorde.defined sample_ary[0]
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is true if the variable is an array element with a value"; ( _shpec_failures=0
    declare -a sample_ary=()
    unset -v sample_ary
    sample_ary=( 'a value' )
    concorde.defined sample_ary[0]
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is false if the variable is an element of an unset hash"; ( _shpec_failures=0
    unset -v sample_hsh
    concorde.defined sample_hsh[index]
    assert unequal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is false if the variable is an unset hash element"; ( _shpec_failures=0
    unset -v sample_hsh
    declare -A sample_hsh=()
    concorde.defined sample_hsh[zero]
    assert unequal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is true if the variable is an empty array element"; ( _shpec_failures=0
    unset -v sample_hsh
    declare -A sample_hsh=( [zero]='' )
    concorde.defined sample_hsh[zero]
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is true if the variable is an array element with a value"; ( _shpec_failures=0
    unset -v sample_hsh
    declare -A sample_hsh=( [zero]=0 )
    concorde.defined sample_hsh[zero]
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.emit
  it "echos hello"; ( _shpec_failures=0
    assert equal hello "$( $(concorde.emit 'echo hello') )"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "executes a compound statement"; ( _shpec_failures=0
    assert equal $'hello\nthere' "$( $(concorde.emit 'echo hello; echo there') )"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "executes a multiline statement"; ( _shpec_failures=0
    assert equal $'hello\nthere' "$( $(concorde.emit $'echo hello\necho there') )"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "declares a variable"; ( _shpec_failures=0
    $(concorde.emit 'declare sample=example')
    assert equal example "$sample"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "returns"; ( _shpec_failures=0
    assert equal '' "$($(concorde.emit return); echo hello)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.escape_items
  it "creates a quoted string from some items"; ( _shpec_failures=0
    concorde.escape_items 'one two' three
    assert equal 'one\ two three' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.get
  it "removes the leading whitespace from each line"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      one
      two
    EOS
    assert equal $'one\ntwo' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "doesn't remove leading whitespace in excess of the first line"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      one
       two
    EOS
    assert equal $'one\n two' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "doesn't touch a line which doesn't match the leading space"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      one
     two
    EOS
    assert equal $'one\n     two' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.get_raw
  it "gets stdin in __"; ( _shpec_failures=0
    concorde.get_raw <<<sample
    assert equal sample "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "returns true"; ( _shpec_failures=0
    concorde.get_raw <<<sample
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "gets a multiline string"; ( _shpec_failures=0
    concorde.get_raw <<<$'hey\nthere'
    assert equal $'hey\nthere' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "preserves leading and trailing non-newline whitespace"; ( _shpec_failures=0
    concorde.get_raw <<<' sample '
    assert equal ' sample ' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.grab
  it "errors if the second argument isn't 'from'"; ( _shpec_failures=0
    $(concorde.grab one two)
    assert equal '(113) (1) (ArgumentError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "instantiates a key/value pair from a hash literal as a local"; ( _shpec_failures=0
    $(concorde.grab one from one=1)
    assert equal 1 "$one"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "instantiates more than one key/value pair"; ( _shpec_failures=0
    $(concorde.grab 'one two' from 'one=1 two=2')
    assert equal '(1) (2)' "($one) ($two)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "grabs if the list contains newlines"; ( _shpec_failures=0
    $(concorde.grab '
        one
        two
      ' from 'one=1 two=2')
    assert equal '(1) (2)' "($one) ($two)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "doesn't set the variable if not in the hash and the variable is set locally"; ( _shpec_failures=0
    declare sample=example
    $(concorde.grab sample from '')
    assert equal example "$sample"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "creates the variable if not in the hash and the variable is not set locally"; ( _shpec_failures=0
    unset -v sample
    $(concorde.grab sample from '')
    concorde.defined sample
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.grabkw
  it "errors if the second argument isn't 'from'"; ( _shpec_failures=0
    $(concorde.grabkw one two)
    assert equal '(113) (1) (ArgumentError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "instantiates a key/value pair from a hash literal as a local"; ( _shpec_failures=0
    $(concorde.grabkw one from one="0 1")
    assert equal '0 1' "$one"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "instantiates key/value pairs from a hash literal"; ( _shpec_failures=0
    set -- one="0 1" two="3 4"
    $(concorde.grabkw 'one two' from "$@")
    assert equal '(0 1) (3 4)' "($one) ($two)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "grabs from a non-argument"; ( _shpec_failures=0
    set --
    $(concorde.grabkw one from "$@")
    assert equal '' "$one"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "grabs from an empty argument"; ( _shpec_failures=0
    $(concorde.grabkw one from '')
    assert equal '' "$one"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.hash
  it "creates an empty hash from an empty literal"; ( _shpec_failures=0
    $(concorde.hash result_hsh='')
    declare -p result_hsh >/dev/null
    assert equal '(0) (0)' "($?) (${#result_hsh[@]})"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "creates a hash from a literal"; ( _shpec_failures=0
    $(concorde.hash result_hsh='zero="0 1" one="2 3"')
    assert equal '(0 1) (2 3)' "(${result_hsh[zero]}) (${result_hsh[one]})"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.hashkw
  it "creates a hash from multiple keyword arguments"; ( _shpec_failures=0
    $(concorde.hashkw result_hsh=zero="0 1" one="2 3")
    assert equal '(0 1) (2 3)' "(${result_hsh[zero]}) (${result_hsh[one]})"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.is_local
  it "is true if there is a local variable"; ( _shpec_failures=0
    samplef () { local sample=''; $(concorde.is_local sample) ;}
    samplef
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is false if there is no variable defined"; ( _shpec_failures=0
    samplef () { $(concorde.is_local sample) ;}
    samplef
    rc=$?
    [[ -n ${sample+x} ]]
    assert equal '(1) (1)' "($?) ($rc)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is false if there is a variable defined in the global scope"; ( _shpec_failures=0
    declare -g sample=''
    samplef () { $(concorde.is_local sample) ;}
    samplef
    assert equal 1 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "is false if there is a variable defined in a higher scope"; ( _shpec_failures=0
    samplef   () { $(concorde.is_local sample)  ;}
    samplef2  () { local sample=''; samplef     ;}
    samplef2
    assert unequal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.parse_options
  it "errors on an undefined option"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      -o '' '' 'a flag'
    EOS
    $(concorde.parse_options "$__" -a)
    assert equal "(113) (1) (OptionError) (unsupported option '-a')" "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts no options on the command line when options are defined"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      -o '' '' 'a flag'
    EOS
    $(concorde.parse_options "$__")
    assert equal '' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts a short flag option"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      -o '' '' 'a flag'
    EOS
    $(concorde.parse_options "$__" -o)
    $(concorde.grab o_flag from "$__")
    assert equal 1 "$o_flag"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts a long flag option"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      '' --option '' 'a flag'
    EOS
    $(concorde.parse_options "$__" --option)
    $(concorde.grab option_flag from "$__" )
    assert equal 1 "$option_flag"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts a hyphenated long flag option"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      '' --hyphen-option '' 'a flag'
    EOS
    $(concorde.parse_options "$__" --hyphen-option)
    $(concorde.grab hyphen_option_flag from "$__" )
    assert equal 1 "$hyphen_option_flag"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts a short argument option"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      -o '' argument 'an argument'
    EOS
    $(concorde.parse_options "$__" -o value )
    $(concorde.grab argument from "$__"     )
    assert equal value "$argument"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts a long argument option without an equals sign"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      '' --option argument 'an argument'
    EOS
    $(concorde.parse_options "$__" --option value )
    $(concorde.grab argument from "$__"           )
    assert equal value "$argument"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts a long argument option with an equals sign"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      '' --option argument 'an argument'
    EOS
    $(concorde.parse_options "$__" --option=value )
    $(concorde.grab argument from "$__"           )
    assert equal value "$argument"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts multiple short options in one"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      -o '' '' 'a flag'
      -p '' '' 'a flag'
    EOS
    $(concorde.parse_options "$__" -op            )
    $(concorde.grab 'o_flag p_flag' from "$__")
    assert equal '(1) (1)' "($o_flag) ($p_flag)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts multiple short options with the last an argument"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      -o '' '' 'a flag'
      -p '' argument 'an argument'
    EOS
    $(concorde.parse_options "$__" -op value    )
    $(concorde.grab 'o_flag argument' from "$__")
    assert equal '1 value' "$o_flag $argument"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "accepts a combination of option types"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      ''  --option1 ''        'flag 1'
      -o  ''        ''        'flag 2'
      ''  --option3 argument3 'argument 3'
      -p  ''        argument4 'argument 4'
      -q  --option5 ''        'flag 5'
      -r  --option6 argument6 'argument 6'
    EOS
    $(concorde.parse_options "$__" --option1 -o --option3=value3 -p value4 --option5 -r value6)
    $(concorde.grab '
        option1_flag
        o_flag
        argument3
        argument4
        option5_flag
        argument6
      ' from "$__" )
    assert equal '(1) (1) (value3) (value4) (1) (value6)' "($option1_flag) ($o_flag) ($argument3) ($argument4) ($option5_flag) ($argument6)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "outputs arguments"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      -o  '' '' 'a flag'
    EOS
    $(concorde.parse_options "$__" -o arg1 arg2 )
    assert equal '(arg1) (arg2)' "($1) ($2)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "doesn't output arguments if none are provided"; ( _shpec_failures=0
    concorde.get <<'    EOS'
      -o  '' '' 'a flag'
    EOS
    $(concorde.parse_options "$__" -o)
    assert equal 0 $#
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.part
  it "raises an error is the second argument isn't 'on'"; ( _shpec_failures=0
    concorde.part one@two @
    assert equal '(113) (1) (ArgumentError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "splits a string on a delimiter"; ( _shpec_failures=0
    concorde.part one@two on @
    assert equal 'one two' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "doesn't expand globs"; ( _shpec_failures=0
    concorde.part '*' on @
    assert equal '\*' "$__"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "doesn't turn off globbing"; ( _shpec_failures=0
    concorde.part '*' on @
    [[ $- != *f* ]]
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.raise
  it "returns"; ( _shpec_failures=0
    samplef () { $(concorde.raise SampleError); echo hello ;}
    result=$(samplef)
    assert equal '' "$result"
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "has a result code of 113"; ( _shpec_failures=0
    samplef () { $(concorde.raise SampleError) ;}
    samplef
    assert equal 113 $?
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "stores the result code of the last command by default"; ( _shpec_failures=0
    samplef () { ( exit 123 ); $(concorde.raise SampleError) ;}
    samplef
    assert equal 123 "$__errcode"
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "stores a blank error message by default"; ( _shpec_failures=0
    __errmsg=sample
    samplef () { $(concorde.raise SampleError) ;}
    samplef
    assert equal '' "$__errmsg"
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "allows no return to be specified"; ( _shpec_failures=0
    samplef () { concorde.raise SampleError return=0 ;}
    $(samplef)
    assert equal 113 $?
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "allows the error code to be specified"; ( _shpec_failures=0
    samplef () { ( exit 123 ); $(concorde.raise SampleError rc=222) ;}
    samplef
    assert equal 222 "$__errcode"
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "reraises an exception"; ( _shpec_failures=0
    samplef   () { $(concorde.raise SampleError "a sample error" rc=1) ;}
    samplef2  () { samplef || $(concorde.raise)                        ;}
    samplef2
    assert equal '(113) (1) (SampleError) (a sample error)' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "raises a standarderror by default"; ( _shpec_failures=0
    samplef () { $(concorde.raise) ;}
    samplef
    assert equal '(113) (0) (StandardError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end
end

describe concorde.repr_array
  it "errors on an undefined variable"; ( _shpec_failures=0
    concorde.repr_array sample
    assert equal '(113) (1) (ArgumentError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "generates a representation of an empty array"; ( _shpec_failures=0
    sample_ary=()
    concorde.repr_array sample_ary
    eval "declare -a result_ary=( $__ )"
    assert equal 0 "${#result_ary[@]}"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "generates a representation of an array"; ( _shpec_failures=0
    sample_ary=( zero one )
    concorde.repr_array sample_ary
    eval "declare -a result_ary=( $__ )"
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(zero) (one)' "${result% }"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "generates a representation of an array with a space in an item"; ( _shpec_failures=0
    sample_ary=( "zero one" two )
    concorde.repr_array sample_ary
    eval "declare -a result_ary=( $__ )"
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(zero one) (two)' "${result% }"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "generates a representation of an array with a newline in an item"; ( _shpec_failures=0
    sample_ary=( $'zero\none' two )
    concorde.repr_array sample_ary
    eval "declare -a result_ary=( $__ )"
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal $'(zero\none) (two)' "${result% }"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.repr_hash
  it "errors on an undefined variable"; ( _shpec_failures=0
    concorde.repr_hash sample
    assert equal '(113) (1) (ArgumentError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "generates a representation of an empty hash"; ( _shpec_failures=0
    declare -A sample_hsh=()
    concorde.repr_hash sample_hsh
    eval "declare -A result_hsh=( $__ )"
    assert equal 0 "${#result_hsh[@]}"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "generates a representation of a nested hash variable"; ( _shpec_failures=0
    declare -A sample_hsh=( [zero]=0 [one]="two=2 three=3" )
    concorde.repr_hash sample_hsh
    $(concorde.hash example_hsh="$__"                )
    $(concorde.hash result_hsh="${example_hsh[one]}" )
    for item in $(IFS=$'\n'; sort <<<"${!result_hsh[*]}"); do
      result_ary+=( "(${result_hsh[$item]})" )
    done
    assert equal '(3) (2)' "${result_ary[*]}"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "generates a representation of a nested hash variable with newlines"; ( _shpec_failures=0
    declare -A sample_hsh=( [zero]=0 [one]="two=$'2\n3' four=4" )
    concorde.repr_hash sample_hsh
    $(concorde.hash example_hsh="$__"                )
    $(concorde.hash result_hsh="${example_hsh[one]}" )
    for item in $(IFS=$'\n'; sort <<<"${!result_hsh[*]}"); do
      result_ary+=( "(${result_hsh[$item]})" )
    done
    assert equal $'(4) (2\n3)' "${result_ary[*]}"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.sourced
  it "returns true when called from 'source'"; ( _shpec_failures=0
    source () { concorde.sourced ;}
    source
    assert equal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "returns false when called from anything else"; ( _shpec_failures=0
    samplef () { concorde.sourced ;}
    samplef
    assert unequal 0 $?
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end
end

describe concorde.ssv
  it "creates a multidimensional array from a multiline string"; ( _shpec_failures=0
    $(concorde.ssv result_ary=$'one two\nthree')
    $(concorde.array result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one) (two)' "${result% }"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "creates a multidimensional array from a string with a quoted item"; ( _shpec_failures=0
    $(concorde.ssv result_ary=$'"one two"\nthree')
    $(concorde.array result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two)' "${result% }"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "creates a multidimensional array from a string with a quoted item with an escaped newline"; ( _shpec_failures=0
    $(concorde.ssv result_ary="\$'one\ntwo'"$'\nthree')
    $(concorde.array result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal $'(one\ntwo)' "${result% }"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "creates a multidimensional array from multiple quoted items with a newline in a string"; ( _shpec_failures=0
    $(concorde.ssv result_ary=$'"one two" "three four"\nfive')
    $(concorde.array result_ary="${result_ary[0]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(one two) (three four)' "${result% }"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "creates an array from the second multiple quoted items in a string"; ( _shpec_failures=0
    $(concorde.ssv result_ary=$'"one two" "three four"\n"five six" "seven eight"')
    $(concorde.array result_ary="${result_ary[1]}")
    printf -v result '(%s) ' "${result_ary[@]}"
    assert equal '(five six) (seven eight)' "${result% }"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.stuff
  it "errors if not given 'into'"; ( _shpec_failures=0
    concorde.stuff sample otni ''
    assert equal "(113) (1) (ArgumentError) ()" "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" );: $(( _shpec_failures+=$? ))
  end

  it "inserts a local into a blank hash"; ( _shpec_failures=0
    sample=zero
    concorde.stuff sample into ''
    $(concorde.hash result_hsh="$__")
    assert equal zero "${result_hsh[sample]}"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end

  it "works with multiple variables and a blank hash"; ( _shpec_failures=0
    zero="0 1"
    one="2 3"
    concorde.stuff 'zero one' into ''
    $(concorde.hash result_hsh="$__")
    for item in $(IFS=$'\n'; sort <<<"${!result_hsh[*]}"); do
      result_ary+=( "(${result_hsh[$item]})" )
    done
    assert equal '(2 3) (0 1)' "${result_ary[*]}"
    return "$_shpec_failures" );: $(( _shpec_failures += $? ))
  end
end

describe concorde.xtrace_begin
  it "turns off trace if __xtrace is not set"; ( _shpec_failures=0
    stub_command set 'echo "$@"'

    assert equal '+o xtrace' "$(concorde.xtrace_begin)"
    return "$_shpec_failures" );: $(( _shpec_failures += $?))
  end

  it "doesn't turns off trace if __xtrace is set"; ( _shpec_failures=0
    stub_command set 'echo "$@"'

    __xtrace=1
    assert equal '' "$(concorde.xtrace_begin)"
    return "$_shpec_failures" );: $(( _shpec_failures += $?))
  end
end

describe concorde.xtrace_end
  it "doesn't turn on trace if __xtrace_set is not set"; ( _shpec_failures=0
    stub_command set 'echo "$@"'

    assert equal '' "$(concorde.xtrace_end)"
    return "$_shpec_failures" );: $(( _shpec_failures += $?))
  end

  it "turns on trace if __xtrace_set is set"; ( _shpec_failures=0
    stub_command set 'echo "$@"'

    __xtrace_set=1
    assert equal '-o xtrace' "$(concorde.xtrace_end)"
    return "$_shpec_failures" );: $(( _shpec_failures += $?))
  end
end
