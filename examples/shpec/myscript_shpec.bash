source concorde.bash
$(require_relative ../bin/myscript)

describe myscript_main
  it "outputs 'Hello, world!' when called with no arguments"
    result=$(myscript_main)
    assert equal 'Hello, world!' "$result"
  end

  it "outputs 'Hola, world!' when called with greeting=Hola"
    result=$(myscript_main greeting=Hola)
    assert equal 'Hola, world!' "$result"
  end

  it "outputs 'Hello, world.' when called with mellow_flag=1"
    result=$(myscript_main mellow_flag=1)
    assert equal 'Hello, world.' "$result"
  end

  it "outputs 'Hello, myname!' when called with myname and no options"
    result=$(myscript_main '' myname)
    assert equal 'Hello, myname!' "$result"
  end

  it "outputs multiple greetings when called with multiple names"
    result=$(myscript_main '' myname yourname)
    assert equal $'Hello, myname!\nHello, yourname!' "$result"
  end

  it "works with an option and a name"
    result=$(myscript_main greeting=Hola myname)
    assert equal 'Hola, myname!' "$result"
  end
end
