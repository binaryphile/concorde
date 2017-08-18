source concorde.bash
$(require_relative ../lib/hello)

set -o nounset

describe hello
  it "outputs 'Hello, world!' when called with no arguments"
    result=$(hello)
    assert equal 'Hello, world!' "$result"
  end

  it "outputs 'Hola, world!' when called with Hola"
    result=$(hello Hola)
    assert equal 'Hola, world!' "$result"
  end

  it "outputs 'Hello, myname!' when called with myname"
    result=$(hello '' myname)
    assert equal 'Hello, myname!' "$result"
  end

  it "outputs 'Hello, world.' when called with ."
    result=$(hello '' '' .)
    assert equal 'Hello, world.' "$result"
  end
end
