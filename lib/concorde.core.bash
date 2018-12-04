shopt -s expand_aliases
alias kwargs='(( $# )) && declare'

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
