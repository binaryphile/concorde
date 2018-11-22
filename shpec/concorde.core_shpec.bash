IFS=$'\n'
set -o noglob

shpec_Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $shpec_Dir/shpec/shpec-helper.bash
source $shpec_Dir/lib/concorde.core.bash

describe kwargs
  it "instantiates keyword arguments"
    samplef () {
      kwargs $*
      echo $sample
    }
    result=$(samplef sample=text)
    assert equal text $result
  ti
end_describe

describe var
  var sample

  it "assigns text"
    samplef () {
      sample = text
      echo $sample
    }
    result=$(samplef)
    assert equal text $result
  ti

  it "allows multiple assignments"
    samplef () {
      sample = sample
      sample = text
      echo $sample
    }
    result=$(samplef)
    assert equal text $result
  ti

  it "doesn't leave a global variable"
    samplef () {
      sample = text
      echo $sample
    }
    samplef >/dev/null
    ! [[ -v sample ]]
    assert equal 0 $?
  ti

  it "captures builtin output"
    samplef () {
      sample = echo text
      echo $sample
    }
    result=$(samplef)
    assert equal text $result
  ti

  it "feeds the variable as the last argument to a function"
    assign () {
      local -n ref_=$2
      ref_=$1
    }
    samplef () {
      sample = assign text
      echo $sample
    }
    result=$(samplef)
    assert equal text $result
  ti
end_describe
