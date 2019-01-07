all () {
  local item_

  for item_ in $1; do
    $2 $item_ || return
  done
}

any () {
  for item_ in $1; do
    $2 $item_ && return
  done
}

include? () {
  [[ $IFS$1$IFS == *"$IFS$2$IFS"* ]]
}
