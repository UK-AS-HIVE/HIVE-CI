#!/bin/sh

function buildMeteor() {
  echo -e "\033[1mThis is a meteor ${METEOR_VERSION} app, attempting to build Meteor and iOS archives\033[0m"

  # Hack to add private package
  if [[ ! -z `grep hive:accounts-linkblue .meteor/packages` ]]
  then
    mkdir -p packages
    cd packages
    git clone https://${GH_API_TOKEN}:x-oauth-basic@github.com/UK-AS-HIVE/meteor-accounts-linkblue hive:accounts-linkblue
    cd ..
  fi
  meteor add-platform ios
  meteorApplyDevPatches
  meteor build --debug --directory build --server ${DEV_SERVER}/${REPO}

  if [[ -e build/bundle ]]
  then
    #This is a weird way to do this.
    rm -rf ${STAGE_DIR}/var/meteor/${REPO}
    mkdir -p ${STAGE_DIR}/var/meteor/${REPO}
    cp -R build/bundle/ ${STAGE_DIR}/var/meteor/${REPO}
  fi

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
    xcodebuild archive -project ${REPO}.xcodeproj -scheme ${REPO} -archivePath ${REPO}.xcarchive
    xcodebuild -exportArchive -archivePath ${REPO}.xcarchive -exportPath ${REPO} -exportFormat ipa -exportProvisioningProfile "HiveMobilePlatform InHouse ProvisioningProfile"
    generateManifest
    # TODO: this should be replace by the actual deployment
    mkdir -p ${STAGE_DIR}/var/www
    cp ${REPO}.ipa ${STAGE_DIR}/var/www/
  fi
  
  BUILD_STATUS=$?

  #TODO deploy using rsync, etc.
}

# Execute from within the main directory before building
function meteorApplyDevPatches() {
  echo "Patching html href and src attributes for relative routes"
  find . -depth 1 -name "*.html" | xargs gsed -i 's/href="\//href="\/'"${REPO}"'\//g'
  find . -depth 1 -name "*.html" | xargs gsed -i 's/src="\//src="\/'"${REPO}"'\//g'
  find client -name "*.html" -type f -print0 | xargs -0 gsed -i 's/href="\//href="\/'"${REPO}"'\//g'
  find client -name "*.html" -type f -print0 | xargs -0 gsed -i 's/src="\//src="\/'"${REPO}"'\//g'

  echo "Patching css url() references for relative routes"
  find client -name "*.css" -type f -print0 | xargs -0 gsed -i "s/url(\(['\"]\)\?\(\/\)\?/url(\1\2${REPO}\//g"

  mkdir -p lib/relativeRoutes
  cp ${ORIG_DIR}/includes/meteor/relativeRoutes.js lib/relativeRoutes/relativeRoutes.js
}

function deployMeteor() {
  #Deploy to development servers; if a tagged release, deploy to production server as well.
  
  if [[ -z `git describe --exact-match --tags HEAD| grep fatal` ]]
  then
    #There has to be something here or it breaks everything. This is wrong though.
    echo "Tagged"
    # This is a tagged release, deploy to production server
  fi

  generateNginx
  generateInitd
  generateHtmlindex
}

function generateManifest() {
  PROJ_DIR=`pwd`
  info_plist=$(ls ${REPO}/*Info.plist | sed -e 's/\.plist//')
  bundle_id=$(defaults read $PROJ_DIR/$info_plist CFBundleIdentifier)
  cat << EOF > ${REPO}.plist
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
              <string>
                ${APPS_SERVER}/${REPO}.ipa
              </string>
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

#TODO: Deploy with the .ipa
mkdir -p ${STAGE_DIR}/var/www
cp ${REPO}.plist ${STAGE_DIR}/var/www/
} 
