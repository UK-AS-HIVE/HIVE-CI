//import {Assets} from 'meteor/tools';

export const ios = {
  name: 'Building iOS app',
  cmd: Assets.getText('scripts/build/ios.sh') + "buildIos"
};
