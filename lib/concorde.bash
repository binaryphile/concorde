concorde.defined () {
  declare -p "${1%%[*}" >/dev/null 2>&1 && [[ -n ${!1+x} ]]
}

concorde.emit () {
  concorde.xtrace_begin
  printf 'eval eval %q' "$1"
  concorde.xtrace_end
}

concorde.xtrace_begin () {
  (( ${__xtrace:-} )) && return;:
  [[ $- != *x* ]] && __xtrace_set=$? || __xtrace_set=$?
  set +o xtrace
}

concorde.xtrace_end () {
  (( ${__xtrace_set:-} )) && set -o xtrace;:
}
