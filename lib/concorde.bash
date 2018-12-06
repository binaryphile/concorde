concorde_Dir=$(dirname $(readlink -f $BASH_SOURCE))

shopt -s expand_aliases
alias kwargs='(( $# )) && declare'

source $concorde_Dir/as module          \
  ary=$concorde_Dir/concorde.array.bash

alias_var () {
  local item

  for item; do
    eval "alias $item='_var_helper_ $item'"
  done
}

_var_helper_ () {
  [[ $3 == printf ]] && {
    printf -v $1 ${*:3}
    return
  }
  case $(type -t $3) in
    function  ) ${*:3} $1                 ;;
    *         ) printf -v $1 %s $(${*:3}) ;;
  esac
}
