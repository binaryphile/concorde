source $(dirname $(readlink -f $BASH_SOURCE))/module
module.already_loaded && return

shopt -s expand_aliases
alias kwargs='(( $# )) && declare'
