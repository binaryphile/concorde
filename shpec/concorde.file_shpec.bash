describe executable_file?
  it "identifies an executable file"; ( _shpec_failures=0
    dir=$($mktempd)
    directory? "$dir" || return
    touch "$dir"/file
    chmod 755 "$dir"/file
    executable_file? "$dir"/file
    assert equal 0 $?
    $rmtree "$dir"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end

  it "doesn't identify an executable directory"; ( _shpec_failures=0
    dir=$($mktempd)
    directory? "$dir" || return
    mkdir "$dir"/dir
    chmod 755 "$dir"/dir
    executable_file? "$dir"/dir
    assert unequal 0 $?
    $rmtree "$dir"
    return "$_shpec_failures" ); : $(( _shpec_failures += $? ))
  end
end

