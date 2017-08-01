source concorde.bash
$(feature hello)

hello () {
  local    greeting=${1:-Hello}
  local        name=${2:-world}
  local punctuation=${3:-!}

  echo "$greeting, $name$punctuation"
}
