all () {
  local item

  for item in $1; do
    $2 $item || return
  done
}

any () {
  local item

  for item in $1; do
    $2 $item && return
  done
}

include? () {
  [[ $IFS$1$IFS == *"$IFS$2$IFS"* ]]
}
