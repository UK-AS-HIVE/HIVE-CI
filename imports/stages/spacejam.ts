export var spacejam = {
  name: 'spacejam',
  cmd: "if [[ -e .meteor/release && -d packages ]]\nthen\n  spacejam test-packages packages/*\nfi\nif [[ -e package.js ]]\nthen\n spacejam test-packages ./\nfi"
};
