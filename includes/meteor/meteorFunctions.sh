#!/bin/sh

function buildMeteor() {
  echo -e "\033[1mThis is a meteor 0.9 app, attempting to build Meteor and iOS archives\033[0m"

  # Hack to add private package
  if [[ ! -z `grep hive:accounts-linkblue .meteor/packages` ]]
  then
    mkdir -p packages
    cd packages
    git clone https://${GH_API_TOKEN}:x-oauth-basic@github.com/UK-AS-HIVE/meteor-accounts-linkblue hive:accounts-linkblue
    cd ..
  fi
  meteor add-platform ios
  meteor build --debug --directory build --server https://meteordev.as.uky.edu/${REPO}

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

    # TODO: this should be replace by the actual deployment
    cp ${REPO}.ipa ~
  fi

  BUILD_STATUS=$?

  #TODO deploy using rsync, etc.
}

# Execute from within the main directory before building
function meteorApplyDevPatches() {
  echo "Patching html href and src attributes for relative routes"
  ls *.html | xargs sed -i 's/href="\//href="\/'"${REPO_NAME}"'\//g'
  ls *.html | xargs sed -i 's/src="\//src="\/'"${REPO_NAME}"'\//g'
  find client -name "*.html" -type f -print0 | xargs -0 sed -i 's/href="\//href="\/'"${REPO_NAME}"'\//g'
  find client -name "*.html" -type f -print0 | xargs -0 sed -i 's/src="\//src="\/'"${REPO_NAME}"'\//g'

  echo "Patching css url() references for relative routes"
  find client -name "*.css" -type f -print0 | xargs -0 sed -i "s/url(\(['\"]\)\?\(\/\)\?/url(\1\2${REPO_NAME}\//g"

  mkdir -p lib/relativeRoutes
  cp ${ORIG_PWD}/includes/meteor/relativeRoutes.js lib/relativeRoutes/relativeRoutes.js
}

