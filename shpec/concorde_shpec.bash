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
