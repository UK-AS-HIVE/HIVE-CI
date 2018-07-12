export var mocha = {
  name: 'mocha',
  cmd: "if [[ -e .meteor/release && -n `grep dispatch:mocha-phantomjs .meteor/packages` ]]\nthen\n  if [[ -e package.json ]]\n  then\n    meteor npm install\n  fi\n  meteor test --port=4096 --once --driver-package=dispatch:mocha-phantomjs\nfi"
};
