shopt -s expand_aliases
alias kwargs='(( $# )) && declare'

alias_var () {
  local item

  for item; do
    eval "alias $item='_var_helper_ $item'"
  done
}

_var_helper_ () {
  case $(type -t $3) in
    builtin|file  ) printf -v $1 %s $(${*:3}) ;;
    function      ) ${*:3} $1                 ;;
  esac
}
