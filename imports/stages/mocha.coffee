exports.mocha =
  name: 'mocha'
  cmd: """
    if [[ -e .meteor/release && -n `grep dispatch:mocha-phantomjs .meteor/packages` ]]
    then
      if [[ -e package.json ]]
      then
        meteor npm install
      fi
      meteor test --port=4096 --once --driver-package=dispatch:mocha-phantomjs
    fi
  """

