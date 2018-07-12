export const gagarin = {
  name: 'gagarin',
  cmd: "if [[ -e .meteor/release && -d tests/gagarin ]]\nthen\n  chromedriver &\n  gagarin -v\nfi"
};
