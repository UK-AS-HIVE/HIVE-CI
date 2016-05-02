exports.gagarin =
  name: 'gagarin'
  cmd: """
    if [[ -e .meteor/release && -d tests/gagarin ]]
    then
      chromedriver &
      gagarin -v
    fi
  """

