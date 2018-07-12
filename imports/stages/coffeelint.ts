export const coffeelint = {
  name: 'CoffeeLint',
  cmd: "CF=`find . -name \"*.coffee\" | { grep -v -E \"^\.\/\.|packages|imports\/contrib\/|compatibility\/\" || true; }`\ntest -z \"${CF}\" || coffeelint ${CF}",
  errorMessage: function(out) {
    var clErrors, ref, ref1;
    clErrors = out != null ? (ref = out.trim().split('\n').pop().match(/\ [0-9]{1,} errors?/)) != null ? (ref1 = ref.shift()) != null ? ref1.trim() : void 0 : void 0 : void 0;
    return "CoffeeLint found " + clErrors;
  }
};