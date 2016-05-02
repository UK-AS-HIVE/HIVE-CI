exports.ios =
  name: 'Building iOS app'
  cmd:
    Assets.getText('scripts/build/ios.sh') +
    """
      buildIos
    """

