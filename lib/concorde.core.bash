shopt -s expand_aliases
alias kwargs='(( $# )) && declare'

var () {
  local item

  for item; do
    eval "alias $item=\"declare $item; _var_helper_ $item\""
  done
}

_var_helper_ () {
  case $(type -t $3) in
    builtin   ) printf -v $1 %s $(${*:3}) ;;
    function  ) ${*:3} $1                 ;;
    *         ) printf -v $1 %s $3        ;;
  esac
}
