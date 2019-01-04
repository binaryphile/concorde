executable? () {
  [[ -f $1 && -x $1 ]]
}

nonexecutable? () {
  [[ -f $1 && ! -x $1 ]]
}
