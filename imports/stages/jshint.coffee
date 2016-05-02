exports.jshint =
  name: 'jshint'
  cmd: """
      JF=`find . -name "*.js" | { grep -vE "client/compatibility|public/|\.meteor|packages|.min.js" || true; }`
      test -z "${JF}" || jshint ${JF}
    """
  errorMessage: (out) ->
    "jshint found " + out?.trim().split('\n').pop()

