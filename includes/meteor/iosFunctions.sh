
#!/bin/bash

function buildIos {  

  if [[ -e build/ios/project ]]
  then
    cd build/ios/project

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
    defaults write ${PROJ_DIR}/${info_plist} CFBundleIdentifier ${ORG_PREFIX}.${REPO} 

    xcodebuild archive -project ${REPO}.xcodeproj -scheme ${REPO} -archivePath ${REPO}.xcarchive
    xcodebuild -exportArchive -archivePath ${REPO}.xcarchive -exportPath ${REPO} -exportFormat ipa -exportProvisioningProfile "HiveMobilePlatform InHouse ProvisioningProfile"
    
    generateManifest
    
    mkdir -p ${STAGE_DIR}/var/www
    cp ${REPO}.ipa ${STAGE_DIR}/var/www/
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
            <string>${DEV_SERVER}/${REPO}.ipa</string>
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
mkdir -p ${STAGE_DIR}/var/www
cp ${REPO}.plist ${STAGE_DIR}/var/www/
} 
