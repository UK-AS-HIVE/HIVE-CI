exports.coffeelint =
  name: 'CoffeeLint'
  cmd: """
      CF=`find . -name "*.coffee" | { grep -v -E "^\.\/\.|packages|imports\/contrib\/|compatibility\/" || true; }`
      test -z "${CF}" || coffeelint ${CF}
    """
  errorMessage: (out) ->
    clErrors = out?.trim().split('\n').pop().match(/\ [0-9]{1,} errors?/)?.shift()?.trim()
    "CoffeeLint found #{clErrors}"

