export const jshint = {
  name: 'jshint',
  cmd: "JF=`find . -name \"*.js\" | { grep -vE \"compatibility/|imports/contrib/|public/|\.meteor|packages|.min.js\" || true; }`\ntest -z \"${JF}\" || jshint ${JF}",
  errorMessage: function(out) {
    return "jshint found " + (out != null ? out.trim().split('\n').pop() : void 0);
  }
};
