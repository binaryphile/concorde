export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir --parents -- "$TMPDIR"

set -o nounset

source "$(dirname -- "$(readlink --canonicalize -- "$BASH_SOURCE")")"/../lib/concorde.bash

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
