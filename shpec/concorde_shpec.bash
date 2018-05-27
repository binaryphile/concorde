_echo='printf %s\n'
_mkdir='mkdir --parents --'

export TMPDIR=${TMPDIR:-$HOME/tmp}
$_mkdir "$TMPDIR"

! true && set -o nounset

source "$(dirname -- "$(readlink --canonicalize -- "$BASH_SOURCE")")"/../lib/concorde.bash

describe die
  it "exits without an error message"; ( _shpec_failures=0
    result=$(die 2>&1)
    assert equal '' "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "exits with a default error code of the last command"; ( _shpec_failures=0
    false
    (die)
    result=$?
    (die)
    assert equal '1 0' "$result $?"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "exits with an error message"; ( _shpec_failures=0
    result=$(die aaaaagh 2>&1)
    assert equal aaaaagh "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "exits with an error code"; ( _shpec_failures=0
    (die rc=2)
    assert equal 2 $?
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reports an exception"; ( _shpec_failures=0
    result=$($(raise SampleError return=0 rc=1); die 2>&1)
    assert equal 'SampleError: return code 1' "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reports an exception with message"; ( _shpec_failures=0
    result=$($(raise SampleError "a sample error" return=0 rc=1); die 2>&1 >/dev/null)
    assert equal 'SampleError: a sample error (return code 1)' "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reports an exception and a die message"; ( _shpec_failures=0
    result=$($(raise SampleError return=0 rc=1); die "another message" 2>&1 >/dev/null)
    assert equal "another message" "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reports an exception with message and a die message"; ( _shpec_failures=0
    result=$($(raise SampleError "a sample error" return=0 rc=1); die "another message" 2>&1 >/dev/null)
    assert equal "another message" "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reports a non-error"; ( _shpec_failures=0
    result=$($(raise Sample return=0); die 2>/dev/null)
    assert equal 'Sample: return code 0' "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reports a non-error with message"; ( _shpec_failures=0
    result=$($(raise Sample "a sample error" return=0); die 2>/dev/null)
    assert equal 'Sample: a sample error (return code 0)' "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reports a die message when specified over an error"; ( _shpec_failures=0
    result=$($(raise SampleError return=0); die "another message" 2>/dev/null)
    assert equal "another message" "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reports a die message when specified over a non-error"; ( _shpec_failures=0
    result=$($(raise SampleError "a sample error" return=0); die "another message" 2>/dev/null)
    assert equal "another message" "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end
end

describe concorde.emit
  it "echos hello"; ( _shpec_failures=0
    assert equal hello "$( $(concorde.emit '$_echo hello') )"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "executes a compound statement"; ( _shpec_failures=0
    assert equal $'hello\nthere' "$( $(concorde.emit '$_echo hello; $_echo there') )"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "executes a multiline statement"; ( _shpec_failures=0
    assert equal $'hello\nthere' "$( $(concorde.emit $'$_echo hello\n$_echo there') )"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "declares a variable"; ( _shpec_failures=0
    $(concorde.emit 'declare sample=example')
    assert equal example "$sample"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "returns"; ( _shpec_failures=0
    assert equal '' "$($(concorde.emit return); $_echo hello)"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end
end

describe except
  it "doesn't run the command if there's no exception"; ( _shpec_failures=0
    __errtype=
    result=$(except $_echo sample)
    assert equal '' "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "runs the command if there is an exception"; ( _shpec_failures=0
    __errtype=StandardError
    result=$(except $_echo sample)
    assert equal sample "$result"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "resets the exception"; ( _shpec_failures=0
    __errtype=StandardError
    except
    assert equal '' "$__errtype"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "resets the raise return code"; ( _shpec_failures=0
    __code=0
    except
    assert equal 113 "$__code"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end
end

describe raise
  it "returns"; ( _shpec_failures=0
    samplef () { $(raise SampleError); $_echo hello ;}
    result=$(samplef)
    assert equal '' "$result"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "has a result code of 113"; ( _shpec_failures=0
    samplef () { $(raise SampleError) ;}
    samplef
    assert equal 113 $?
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "stores the result code of the last command by default"; ( _shpec_failures=0
    samplef () { ( exit 123 ); $(raise SampleError) ;}
    samplef
    assert equal 123 "$__errcode"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "stores a blank error message by default"; ( _shpec_failures=0
    __errmsg=sample
    samplef () { $(raise SampleError) ;}
    samplef
    assert equal '' "$__errmsg"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "allows no return to be specified"; ( _shpec_failures=0
    samplef () { raise SampleError return=0 ;}
    $(samplef)
    assert equal '(113) (SampleError)' "($?) ($__errtype)"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "allows the error code to be specified"; ( _shpec_failures=0
    samplef () { ( exit 123 ); $(raise SampleError rc=222) ;}
    samplef
    assert equal 222 "$__errcode"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "reraises an exception"; ( _shpec_failures=0
    __code=0
    samplef   () { $(raise SampleError "a sample error" rc=1) ;}
    samplef2  () { samplef; $(raise)                          ;}
    samplef2
    assert equal '(0) (1) (SampleError) (a sample error)' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "allows no return on a reraises"; ( _shpec_failures=0
    __code=0
    samplef   () { $(raise SampleError "a sample error" rc=1) ;}
    samplef2  () { samplef; raise return=0                    ;}
    $(samplef2)
    assert equal '(0) (1) (SampleError) (a sample error)' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "raises a standarderror by default"; ( _shpec_failures=0
    samplef () { $(raise) ;}
    samplef
    assert equal '(113) (0) (StandardError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end
end

describe try
  it "runs a command"; ( _shpec_failures=0
    result=$(try $_echo sample)
    assert equal sample "$result"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "makes raise return true"; ( _shpec_failures=0
    samplef () { $(raise SampleError rc=1) ;}
    try samplef
    assert equal '(0) (1) (SampleError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end
end

describe concorde.xtrace_begin
  it "turns off trace if __xtrace is not set"; ( _shpec_failures=0
    stub_command set '$_echo "$*"'

    assert equal '+o xtrace' "$(concorde.xtrace_begin)"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't turns off trace if __xtrace is set"; ( _shpec_failures=0
    stub_command set '$_echo "$*"'

    __xtrace=1
    assert equal '' "$(concorde.xtrace_begin)"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end
end

describe concorde.xtrace_end
  it "doesn't turn on trace if __xtrace_set is not set"; ( _shpec_failures=0
    stub_command set '$_echo "$*"'

    assert equal '' "$(concorde.xtrace_end)"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "turns on trace if __xtrace_set is set"; ( _shpec_failures=0
    stub_command set '$_echo "$*"'

    __xtrace_set=1
    assert equal '-o xtrace' "$(concorde.xtrace_end)"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end
end
