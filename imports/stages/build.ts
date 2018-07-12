//import {Assets} from 'meteor/tools';

export const build = {
  name: 'Building Meteor app',
  cmd: Assets.getText('scripts/build/meteor.sh') + "buildMeteor"
};
