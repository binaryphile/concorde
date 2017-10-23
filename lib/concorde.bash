concorde.defined () {
  declare -p "${1%%[*}" >/dev/null 2>&1 && [[ -n ${!1+x} ]]
}

concorde.emit () {
  concorde.xtrace_begin
  printf 'eval eval %q' "$1"
  concorde.xtrace_end
}

concorde.get () {
  concorde.xtrace_begin
  local space

  concorde.get_raw
  space=${__%%[^[:space:]]*}
  printf -v __ %s "${__#$space}"
  printf -v __ %s "${__//$'\n'$space/$'\n'}"
  concorde.xtrace_end
}

concorde.get_raw () {
  IFS=$'\n' read -rd '' __ ||:
}

concorde.xtrace_begin () {
  (( ${__xtrace:-} )) && return;:
  [[ $- != *x* ]] && __xtrace_set=$? || __xtrace_set=$?
  set +o xtrace
}

concorde.xtrace_end () {
  (( ${__xtrace_set:-} )) && set -o xtrace;:
}
