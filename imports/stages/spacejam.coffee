exports.spacejam =
  name: 'spacejam'
  cmd: """
    if [[ -e .meteor/release && -d packages ]]
    then
      spacejam test-packages packages/*
    fi
    if [[ -e package.js ]]
    then
     spacejam test-packages ./
    fi
  """

