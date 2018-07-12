//import {Assets} from 'meteor/tools';

export const android = {
  name: 'Build Android app',
  cmd: Assets.getText('scripts/build/android.sh') + "buildAndroid"
};
