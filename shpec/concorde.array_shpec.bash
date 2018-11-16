describe join
  it "joins strings with no delimiter"
    samples=( a b c )
    s.join samples result
    assert equal abc $result
  ti
end_describe

