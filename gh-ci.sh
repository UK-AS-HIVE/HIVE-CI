#!/bin/bash
 
source settings.sh
source includes/meteor/meteorFunctions.sh
 
ORIG_DIR=`pwd`
BUILD_DIR=${ORIG_DIR}/sandbox/build
STAGE_DIR=${ORIG_DIR}/sandbox/stage
VERSION='0.9'
 
# Find all URLs under github account
REPOS=$(curl -k -u ${GH_API_TOKEN}:x-oauth-basic https://api.github.com/orgs/UK-AS-HIVE/repos | grep clone_url | grep -o -e "https[^\"]\+" | grep -o -e "[a-zA-Z0-9_-]\+\.git$")
 
# Keep log of all tested repos/commits so we dont waste cycles re-testing them
touch log.txt
 
for REPOGIT in ${REPOS}
do
  REPO=`basename -s .git ${REPOGIT}`
  echo -e "\033[1;33m${REPOGIT}"
  tput sgr0
  mkdir -p ${BUILD_DIR}
  cd ${BUILD_DIR}
  if [[ -e "${REPO}/" ]]
  then
    cd ${REPO}
    git reset --hard
    git checkout --
    git clean -dff
    git pull
  else
    git clone --depth=50 https://${GH_API_TOKEN}:x-oauth-basic@github.com/UK-AS-HIVE/${REPOGIT}
    cd ${REPO}
    #Checkout latest commit, regardless of branch. This seems to put us in a detached HEAD state.
    #git checkout `git log --all --format="%H" -1`
  fi
 
  if [[ ! -z `grep "${REPO} $(git rev-parse HEAD)" ../../log.txt` ]]
  then
    # Commit has already been tested, skip
    echo -e "\033[1;37m${REPO} @ $(git rev-parse --short HEAD) has already had CI run, skipping...\033[0;37m"
  else
    
    ### Repo-specific tests here
    if [[ ! -z `grep "${VERSION}"  .meteor/release` ]]
    then
      buildMeteor
      deployMeteor
    elif [[ -e package.js ]]
    then
      echo -e "\033[1mThis is a Meteor package, no tests yet\033[0m"
      BUILD_STATUS=2
    elif [[ -e "${REPO}.info" && -e "${REPO}.module" ]]
    then
      echo -e "\033[1mThis is a Drupal module, no tests yet\033[0m"
      BUILD_STATUS=2
    else
      echo -e "\033[1mNot a Meteor or Drupal package, skipping\033[0m"
 
      BUILD_STATUS=2
    fi
 
    # TODO send better emails (everything in one email to an email group?)
    # TODO deploy to devel server
    # TODO deploy to production server, if tagged release
    echo ${REPO} $(git rev-parse HEAD) >> ${ORIG_PWD}/log.txt
    if [[ ${BUILD_STATUS} -eq 0 ]]
    then
      echo -e "\033[1;32mAutomation success, return status: ${BUILD_STATUS}\033[0;37m"
      echo "PASSED" >> ../../log.txt
      #echo "Hurray! :-) \n\n$(git log HEAD^..HEAD)" | mail -s "Passed: ${REPO}: commit $(git rev-parse --short HEAD)" digipak@gmail.com
    elif [[ ${BUILD_STATUS} -eq 2 ]]
    then
      echo -e "\033[1;32mAutomation skipped, either not a Meteor repository or no tests are available for this Meteor package.\033[0;37m"
      echo "SKIPPED" >> ../../log.txt
    else
      echo -e "\033[1;31mAutomation failure, return status: ${BUILD_STATUS}\033[0;37m"
      echo "FAILED" >> ../../log.txt
      #echo "Sorry :-( \n\n$(git log HEAD^..HEAD)" | mail -s "Failed: ${REPO}: commit $(git rev-parse --short HEAD)" noah.adler@gmail.com
    fi
 
    # Keep a record that this commit has been checked
 
  fi
 
  ### Change back out to top level dir
 
  cd ${ORIG_PWD}

 
done
#TODO format this better (HTML instead of plaintext?)
#test -s log.txt && mail -s "CI results" digipak@gmail.com < log.txt
tput sgr0
