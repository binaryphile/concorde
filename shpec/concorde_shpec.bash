_mkdir='mkdir --parents --'

export TMPDIR=${TMPDIR:-$HOME/tmp}
$_mkdir "$TMPDIR"

! true && set -o nounset

source "$(dirname -- "$(readlink --canonicalize -- "$BASH_SOURCE")")"/../lib/concorde.bash
