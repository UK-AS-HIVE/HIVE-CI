function buildIos {  

  if [[ -e ${BUILD_DIR}/${REPO}-build/ios/project ]]
  then
    cd ${BUILD_DIR}/${REPO}-build/ios/project

    # Currently the onlyway to generate schemes, necessary for build, is to actually open XCode
    open ${REPO}.xcodeproj &
    echo "Waiting for XCode to generate scheme..."
    while [[ ! -e ${REPO}.xcodeproj/project.xcworkspace/xcuserdata ]]
    do
      sleep 2
    done
    sleep 2
    killall Xcode
    wait $!
    
    #Change bundle identifier to match organization.
    #TODO: Update version/build numbers as well
    PROJ_DIR=`pwd`
    info_plist=$(ls ${REPO}/*Info.plist | sed -e 's/\.plist//')
    defaults write ${PROJ_DIR}/${info_plist} CFBundleIdentifier ${ORG_REVERSE_URL}.${REPO}

    #Make sure we are signing for distribution
    gsed -i 's/\(CODE_SIGN_IDENTITY.*\)Developer/\1Distribution/' ${REPO}.xcodeproj/project.pbxproj

    xcodebuild archive -project ${REPO}.xcodeproj -scheme ${REPO} -archivePath ${REPO}.xcarchive
    xcodebuild -exportArchive -archivePath ${REPO}.xcarchive -exportPath ${REPO} -exportFormat ipa -exportProvisioningProfile "UK A&S In-House"

    generateManifest
    
    if [[ ! -z ${TARGET_APP_PATH} ]]
    then
      mkdir -p ${STAGE_DIR}/var/www/${TARGET_APP_PATH}
      cp ${REPO}.ipa ${STAGE_DIR}/var/www/${TARGET_APP_PATH}
    fi
  fi
}


function generateManifest() {
  PROJ_DIR=`pwd`
  info_plist=$(ls ${REPO}/*Info.plist | sed -e 's/\.plist//')
  bundle_id=$(defaults read $PROJ_DIR/$info_plist CFBundleIdentifier)
  cat << EOF > ${REPO}.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>items</key>
    <array>
      <dict>
        <key>assets</key>
        <array>
          <dict>
            <key>kind</key>
            <string>software-package</string>
            <key>url</key>
            <string>${TARGET_PROTOCOL}//${TARGET_HOSTNAME}:${TARGET_PORT}${TARGET_APP_PATH}${REPO}.ipa</string>
          </dict>
        </array>
        <key>metadata</key>
        <dict>
          <key>bundle-identifier</key>
          <string>$bundle_id</string>
          <key>kind</key>
          <string>software</string>
          <key>title</key>
          <string>${REPO}</string>
        </dict>
      </dict>
    </array>
  </dict>
</plist>
EOF

#Copy the manifest to the www stage directory.
if [[ ! -z ${TARGET_APP_PATH} ]]
then
  echo "Copying iOS app and manifest to ${TARGET_APP_PATH}"
  mkdir -p ${STAGE_DIR}/var/www/${TARGET_APP_PATH}
  cp ${REPO}.plist ${STAGE_DIR}/var/www/${TARGET_APP_PATH}
fi
} 
