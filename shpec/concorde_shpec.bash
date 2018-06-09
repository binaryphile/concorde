_echo='printf %s\n'
_mkdir='mkdir --parents --'
_mktempd='mktemp --directory --quiet'
_rmtree='rm --recursive --force --'
_touch='touch --'

export TMPDIR=${TMPDIR:-$HOME/tmp}
$_mkdir "$TMPDIR"

! true && set -o nounset

source "$(dirname -- "$(readlink --canonicalize -- "$BASH_SOURCE")")"/../lib/concorde.bash

describe concorde
  it "is a module"; ( _shpec_failures=0
    [[ -v __hmodules[concorde] ]]
    assert equal 0 $?
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end
end

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

describe __dir
  it "is set to the caller's directory"; ( _shpec_failures=0
    assert equal "$(dirname -- "$(readlink --canonicalize -- "$BASH_SOURCE")")" "$__dir"
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

describe import
  it "imports a module"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    echo sample=1 >"$dir"/sample.bash
    $(PATH=$dir; import sample)
    assert equal 1 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports a module from the second element in the path"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    echo sample=1 >"$dir"/sample.bash
    $(PATH=.:$dir; import sample)
    assert equal 1 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "raises an error if it can't find the module"; ( _shpec_failures=0
    $(PATH=.; import sample)
    assert equal '(113) (1) (ImportError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "raises an error if it can't find the module in a multi-element path"; ( _shpec_failures=0
    $(PATH=.:.; import sample)
    assert equal '(113) (1) (ImportError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports a package"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_echo sample=1 >"$dir"/sample/__init.bash
    $(PATH=$dir; import sample)
    assert equal 1 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports a package from the second element in the path"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_echo sample=1 >"$dir"/sample/__init.bash
    $(PATH=.:$dir; import sample)
    assert equal 1 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports a submodule"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_touch "$dir"/sample/__init.bash
    $_echo sample=1 >"$dir"/sample/example.bash
    $(PATH=$dir; import sample.example)
    assert equal 1 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports the parent of a submodule"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_echo sample=1 >"$dir"/sample/__init.bash
    $_touch "$dir"/sample/example.bash
    $(PATH=$dir; import sample.example)
    assert equal 1 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports the submodule after the parent"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_echo sample=1 >"$dir"/sample/__init.bash
    $_echo sample=2 >"$dir"/sample/example.bash
    $(PATH=$dir; import sample.example)
    assert equal 2 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "raises an error if it can't find the submodule in a valid package"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_touch "$dir"/sample/__init.bash
    $(PATH=$dir; import sample.example)
    assert equal '(113) (1) (ImportError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports a subpackage"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample/example
    $_touch "$dir"/sample/__init.bash
    $_echo sample=1 >"$dir"/sample/example/__init.bash
    $(PATH=$dir; import sample.example)
    assert equal 1 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports the parent of a subpackage"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample/example
    $_echo sample=1 >"$dir"/sample/__init.bash
    $_touch "$dir"/sample/example/__init.bash
    $(PATH=$dir; import sample.example)
    assert equal 1 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "imports the subpackage after the parent"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample/example
    $_echo sample=1 >"$dir"/sample/__init.bash
    $_echo sample=2 >"$dir"/sample/example/__init.bash
    $(PATH=$dir; import sample.example)
    assert equal 2 "$sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "raises an error if it can't find the subpackage in a valid package"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample/example
    $_touch "$dir"/sample/__init.bash
    $(PATH=$dir; import sample.example)
    assert equal '(113) (1) (ImportError) ()' "($?) ($__errcode) ($__errtype) ($__errmsg)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a module's functions with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo 'sample.sample () { :;}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t s.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a module's functions with a leading space with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo ' sample.sample () { :;}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t s.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a module's functions with text and a leading space with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo ':; sample.sample () { :;}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t s.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a module's function calls with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo $'sample.sample () { echo sample ;}\nsample.sample' >"$dir"/sample.bash
    result=$($(PATH=$dir; import sample as=s))
    assert equal sample "$result"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames multiple times in a single line with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo 'sample.sample () { echo sample ;}; sample.sample' >"$dir"/sample.bash
    result=$($(PATH=$dir; import sample as=s))
    assert equal sample "$result"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a module's functions with an as= argument with abutted parentheses"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo 'sample.sample() { :;}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t s.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't rename a module's function with an underscore"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo 'sample_sample () { :;}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t sample_sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't rename a module's function with a character prefix"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo 'asample.sample () { :;}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t asample.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't rename a module's function with an underscore prefix"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo '_sample.sample () { :;}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t _sample.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't rename a module's function with a dot prefix"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo '.sample.sample () { :;}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t .sample.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a package's functions with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_echo 'sample.sample () { :;}' >"$dir"/sample/__init.bash
    $(PATH=$dir; import sample as=s)
    assert equal function "$(type -t s.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a submodule's functions with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_touch "$dir"/sample/__init.bash
    $_echo 'sample.example.sample () { :;}' >"$dir"/sample/example.bash
    $(PATH=$dir; import sample.example as=s)
    assert equal function "$(type -t s.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a subpackage's functions with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample/example
    $_touch "$dir"/sample/__init.bash
    $_echo 'sample.example.sample () { :;}' >"$dir"/sample/example/__init.bash
    $(PATH=$dir; import sample.example as=s)
    assert equal function "$(type -t s.sample)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a module's global assignments with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo '_sample_sample=sample' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal sample "$_s_sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't rename a module's globals without an assignment"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo 'echo _sample_sample' >"$dir"/sample.bash
    result=$($(PATH=$dir; import sample as=s))
    assert equal _sample_sample "$result"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't rename a module's globals that are prefixed"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo '_other_sample_sample=sample' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal sample "$_other_sample_sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a package's globals with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_echo '_sample_sample=sample' >"$dir"/sample/__init.bash
    $(PATH=$dir; import sample as=s)
    assert equal sample "$_s_sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a submodule's globals with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_touch "$dir"/sample/__init.bash
    $_echo '_sample_example_sample=sample' >"$dir"/sample/example.bash
    $(PATH=$dir; import sample.example as=s)
    assert equal sample "$_s_sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a subpackage's globals with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample/example
    $_touch "$dir"/sample/__init.bash
    $_echo '_sample_example_sample=sample' >"$dir"/sample/example/__init.bash
    $(PATH=$dir; import sample.example as=s)
    assert equal sample "$_s_sample"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a module's global references with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo $'_sample_sample=sample\nexample=$_sample_sample' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal sample "$example"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a module's braced global references with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo $'_sample_sample=sample\nexample=${_sample_sample}' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal sample "$example"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't rename a module's global references without a dollar sign"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo 'echo _sample_sample' >"$dir"/sample.bash
    result=$($(PATH=$dir; import sample as=s))
    assert equal _sample_sample "$result"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "doesn't rename a module's globals that are postfixed"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_echo $'_sample_sample=sample\nexample=$_sample_sample_one' >"$dir"/sample.bash
    $(PATH=$dir; import sample as=s)
    assert equal '' "$example"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a package's global references with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_echo $'_sample_sample=sample\nexample=$_sample_sample' >"$dir"/sample/__init.bash
    $(PATH=$dir; import sample as=s)
    assert equal sample "$example"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a submodule's global references with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample
    $_touch "$dir"/sample/__init.bash
    $_echo $'_sample_example_sample=sample\nexample=$_sample_example_sample' >"$dir"/sample/example.bash
    $(PATH=$dir; import sample.example as=s)
    assert equal sample "$example"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "renames a subpackage's global references with an as= argument"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_mkdir "$dir"/sample/example
    $_touch "$dir"/sample/__init.bash
    $_echo $'_sample_example_sample=sample\nexample=$_sample_example_sample' >"$dir"/sample/example/__init.bash
    $(PATH=$dir; import sample.example as=s)
    assert equal sample "$example"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end
end

describe concorde.locate_module
  it "finds a module in the path"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    $_touch "$dir"/sample.bash
    oldPATH=$PATH
    PATH=$dir
    concorde.locate_module sample
    eval "result_ary=( $__ )"
    PATH=$oldPATH
    assert equal "$dir/sample.bash" "${result_ary[*]}"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "raises an error if it can't find a module"; ( _shpec_failures=0
    dir=$($_mktempd) || return
    oldPATH=$PATH
    PATH=$dir
    concorde.locate_module sample
    rc=$?
    PATH=$oldPATH
    assert equal '(113) (1) (ImportError) ()' "($rc) ($__errcode) ($__errtype) ($__errmsg)"
    $_rmtree "$dir"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end
end

describe module
  it "doesn't reload"; ( _shpec_failures=0
    $(module sample)
    result=$($(module sample); $_echo hello)
    assert equal '(0) ()' "($?) ($result)"
    return "$_shpec_failures" ); (( _shpec_failures += $? ))
  end

  it "reloads if the second argument is reload=1"; ( _shpec_failures=0
    set -- one reload=1
    $(module sample)
    result=$($(module sample); $_echo hello)
    assert equal hello "$result"
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

describe sourced
  it "returns true when called from 'source'"; ( _shpec_failures=0
    source () { sourced ;}
    source
    assert equal 0 $?
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "returns false when called from anything else"; ( _shpec_failures=0
    samplef () { sourced ;}
    samplef
    assert unequal 0 $?
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end
end

describe strict_mode
  it "sets errexit"; ( _shpec_failures=0
    set +o errexit
    strict_mode on
    [[ $- == *e* ]]
    rc=$?
    strict_mode off
    assert equal 0 "$rc"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "sets nounset"; ( _shpec_failures=0
    set +o nounset
    strict_mode on
    [[ $- == *u* ]]
    rc=$?
    strict_mode off
    assert equal 0 "$rc"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "sets pipefail"; ( _shpec_failures=0
    set +o pipefail
    strict_mode on
    [[ $(set -o) == *pipefail* ]]
    rc=$?
    strict_mode off
    assert equal 0 "$rc"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "sets a callback for the ERR trap"; ( _shpec_failures=0
    trap - ERR
    strict_mode on
    [[ $(trap) == *ERR* ]]
    rc=$?
    strict_mode off
    assert equal 0 "$rc"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end
end

describe concorde.traceback
  it "turns off tracing"; ( _shpec_failures=0
    stub_command strict_mode

    set -o xtrace
    concorde.traceback exit=0 2>/dev/null
    [[ $- != *x* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "prints the source line which errored"; ( _shpec_failures=0
    stub_command strict_mode

    result=$(concorde.traceback 2>&1)
    [[ $result == *'result=$(concorde.traceback 2>&1)'* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "turns off strict mode"; ( _shpec_failures=0
    stub_command strict_mode '$_echo "$@"'

    result=$(concorde.traceback 2>/dev/null)
    assert equal off "$result"
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "prints a stack trace on stderr"; ( _shpec_failures=0
    stub_command strict_mode

    [[ $(trap concorde.traceback ERR; { false ;} 2>&1) == *"concorde_shpec.bash:804: in 'source'"* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "prints an unspecified error if reporting a normal error"; ( _shpec_failures=0
    stub_command strict_mode

    result=$(concorde.traceback 2>&1)
    [[ $result == *'StandardError: Unspecified Error (return code 0)'* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "prints the type and result of an error if it was raised"; ( _shpec_failures=0
    stub_command strict_mode

    $(raise SampleError return=0 rc=3)
    result=$(concorde.traceback 2>&1)
    [[ $result == *'SampleError: return code 3'* ]]
    assert equal 0 $?
    return "$_shpec_failures" ); (( _shpec_failures+=$? ))
  end

  it "prints the message of an error if it was raised"; ( _shpec_failures=0
    stub_command strict_mode

    $(raise SampleError "a sample error" return=0 rc=3)
    result=$(concorde.traceback 2>&1)
    [[ $result == *'SampleError: a sample error (return code 3)'* ]]
    assert equal 0 $?
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
