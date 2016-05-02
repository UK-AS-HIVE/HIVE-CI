exports.android =
  name: 'Build Android app'
  cmd:
    Assets.getText('scripts/build/android.sh') +
    """
      buildAndroid
    """

