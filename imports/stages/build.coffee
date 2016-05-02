exports.build =
  name: 'Building Meteor app'
  cmd:
    Assets.getText('scripts/build/meteor.sh') +
    """
      buildMeteor
    """
