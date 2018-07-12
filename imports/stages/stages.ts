import {coffeelint} from './coffeelint';
import {jshint} from './jshint';
import {spacejam} from './spacejam';
import {mocha} from './mocha';
import {gagarin} from './gagarin';
import {build} from './build';
import {ios} from './ios';
import {android} from './android';
import {generateNginx} from './generateNginx';
import {deploy} from './deploy';


export const Stages = {
  coffeelint: coffeelint,
  jshint: jshint,
  spacejam: spacejam,
  mocha: mocha,
  gagarin: gagarin,
  build: build,
  ios: ios,
  android: android,
  generateNginx: generateNginx,
  deploy: deploy
}