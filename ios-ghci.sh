#!/bin/bash
 
source settings.sh
 
ORIG_PWD=`pwd`
VERSION='0.9'
 
# Find all URLs under github account
REPOS=$(curl -k -u ${GH_API_TOKEN}:x-oauth-basic https://api.github.com/orgs/UK-AS-HIVE/repos | grep clone_url | grep -o -e "https[^\"]\+" | grep -o -e "[a-zA-Z0-9_-]\+\.git$")
 
# Keep log of all tested repos/commits so we dont waste cycles re-testing them
touch log.txt
 
for REPOGIT in ${REPOS}
do
  REPO=`basename -s .git ${REPOGIT}`
  echo -e "\033[1;30m${REPOGIT}\033[0;30m"
 
  rm -rf sandbox/
  mkdir sandbox
  cd sandbox
  git clone --depth=50 https://${GH_API_TOKEN}:x-oauth-basic@github.com/UK-AS-HIVE/${REPOGIT}
  cd ${REPO}
 
  if [[ ! -z `grep "${REPO} $(git rev-parse HEAD)" ../../log.txt` ]]
  then
    # Commit has already been tested, skip
    echo -e "\033[1;37m${REPO} @ $(git rev-parse --short HEAD) has already had CI run, skipping...\033[0;37m"
  else
    
    ### Repo-specific tests here
    if [[ ! -z `grep "${VERSION}"  .meteor/release` ]]
    then
      echo "This is a meteor 0.9 app, attempting to add iOS platform and build"

      # Hack to add private package
      if [[ ! -z `grep hive:accounts-linkblue .meteor/packages` ]]
      then
        cd packages
        git clone https://${GH_API_TOKEN}:x-oauth-basic@github.com/UK-AS-HIVE/meteor-accounts-linkblue hive:accounts-linkblue
        cd ..
      fi

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
    elif [[ -e package.js ]]
    then
      echo "This is a Meteor package, no tests yet"
      BUILD_STATUS=2
    elif [[ -e "${REPO}.info" && -e "${REPO}.module" ]]
    then
      echo "This is a Drupal module, no tests yet"
      BUILD_STATUS=2
    else
      echo "what kind of repo is this?"
 
      BUILD_STATUS=2
    fi
 
    # TODO send better emails (everything in one email to an email group?)
    # TODO deploy to devel server
    # TODO deploy to production server, if tagged release
    if [[ ${BUILD_STATUS} -eq 0 ]]
    then
      echo -e "\033[1;32mAutomation success, return status: ${BUILD_STATUS}\033[0;37m"
      #echo "Hurray! :-) \n\n$(git log HEAD^..HEAD)" | mail -s "Passed: ${REPO}: commit $(git rev-parse --short HEAD)" digipak@gmail.com
    elif [[ ${BUILD_STATUS} -eq 2 ]]
    then
      echo -e "\033[1;32mAutomation skipped, either not a Meteor repository or no tests are available for this Meteor package.\033[0;37m"
    else
      echo -e "\033[1;31mAutomation failure, return status: ${BUILD_STATUS}\033[0;37m"
      #echo "Sorry :-( \n\n$(git log HEAD^..HEAD)" | mail -s "Failed: ${REPO}: commit $(git rev-parse --short HEAD)" noah.adler@gmail.com
    fi
 
    # Keep a record that this commit has been checked
    echo ${REPO} $(git rev-parse HEAD) >> ../../log.txt
 
  fi
 
  ### Change back out to top level dir
 
  cd ${ORIG_PWD}
  rm -rf sandbox/
 
done
