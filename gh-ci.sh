#!/bin/bash
 
source settings.sh
source includes/meteor/meteorFunctions.sh
source includes/meteor/iosFunctions.sh
source includes/deploy/generateNginx.sh
source includes/deploy/generateInitd.sh 
source includes/deploy/generateHtmlindex.sh

ORIG_DIR=`pwd`
BUILD_DIR=${ORIG_DIR}/sandbox/build
STAGE_DIR=${ORIG_DIR}/sandbox/stage
METEOR_VERSION='0.9'
 
# Find all URLs under github account
REPOS=$(curl -k -u ${GH_API_TOKEN}:x-oauth-basic "https://api.github.com/orgs/${ORG_NAME}/repos?per_page=100" | grep clone_url | grep -o -e "https[^\"]\+" | grep -o -e "[a-zA-Z0-9_-]\+\.git$")
 
# Keep log of all tested repos/commits so we dont waste cycles re-testing them
touch log.txt
 
function main() {
  for REPOGIT in ${REPOS}
  do
    REPO=`basename -s .git ${REPOGIT}`
    echo -e "\033[1;33m${REPOGIT}"
    tput sgr0

    #TODO: refector into multiple phases
    #update
    build
    #test
    #stage

    ### Change back out to top level dir
    cd ${ORIG_DIR}
  done

  #TODO: global processing after all repos have been iterated
  #deployGlobal
  #notifyGlobal
}

function build() {
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
    git clone --depth=50 https://${GH_API_TOKEN}:x-oauth-basic@github.com/${ORG_NAME}/${REPOGIT}
    cd ${REPO}
  fi

  #Checkout latest commit, regardless of branch. This seems to put us in a detached HEAD state.
  git fetch origin '+refs/heads/*:refs/remotes/origin/*'
  git checkout `git log --all --format="%H" -1`
 
  if [[ ! -z `grep "${REPO} $(git rev-parse HEAD)" ${ORIG_DIR}/log.txt` ]]
  then
    # Commit has already been tested, skip
    echo -e "\033[1;37m${REPO} @ $(git rev-parse --short HEAD) has already had CI run, skipping...\033[0;37m"
  else
    
    ### Repo-specific tests here
    if [[ -e .meteor/release ]]
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

    notify
  fi
}


function notify() {
 
    # TODO send better emails (everything in one email to an email group?)
    # TODO deploy to devel server
    # TODO deploy to production server, if tagged release
    cd ${BUILD_DIR}/${REPO}
    echo ${REPO} $(git rev-parse HEAD) >> ${ORIG_DIR}/log.txt
    if [[ ${BUILD_STATUS} -eq 0 ]]
    then
      echo -e "\033[1;32mAutomation success, return status: ${BUILD_STATUS}\033[0;37m"
      echo "PASSED" >> ${ORIG_DIR}/log.txt
      #echo "Hurray! :-) \n\n$(git log HEAD^..HEAD)" | mail -s "Passed: ${REPO}: commit $(git rev-parse --short HEAD)" digipak@gmail.com
    elif [[ ${BUILD_STATUS} -eq 2 ]]
    then
      echo -e "\033[1;32mAutomation skipped, either not a Meteor repository or no tests are available for this Meteor package.\033[0;37m"
      echo "SKIPPED" >> ${ORIG_DIR}/log.txt
    else
      echo -e "\033[1;31mAutomation failure, return status: ${BUILD_STATUS}\033[0;37m"
      echo "FAILED" >> ${ORIG_DIR}/log.txt
      #echo "Sorry :-( \n\n$(git log HEAD^..HEAD)" | mail -s "Failed: ${REPO}: commit $(git rev-parse --short HEAD)" noah.adler@gmail.com
    fi
 
    # Keep a record that this commit has been checked
 

}

function deployToDev() {
  generateNginx
  generateInitd
  generateHtmlindex

  cd ${STAGE_DIR}
  rsync -avz -e ssh var/www/ root@meteordev.as.uky.edu:/var/www
  for APP_DIR in `ls var/meteor`
  do
    echo "Deploying ${APP_DIR} to /var/meteor/${APP_DIR}..."
    rsync -avz --delete --exclude 'programs/server/node_modules/' --exclude 'files/' -e ssh var/meteor/${APP_DIR} root@meteordev.as.uky.edu:/var/meteor
  done

  rsync -avz -e ssh etc/nginx/sites-available/meteordev.conf root@meteordev.as.uky.edu:/etc/nginx/sites-available/meteordev.conf
  rsync -avz -e ssh etc/init.d/ root@meteordev.as.uky.edu:/etc/init.d
}

main
deployToDev
tput sgr0
