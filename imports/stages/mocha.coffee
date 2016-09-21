exports.mocha =
  name: 'mocha'
  cmd: """
    if [[ -e .meteor/release && -z `grep dispatch:mocha-phantomjs .meteor/packages` ]]
    then
      meteor test --once --driver-package=dispatch:mocha-phantomjs
    fi
  """

