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
  if [[ -z `grep android .meteor/platforms` ]]
  then
    echo android >> .meteor/platforms
  fi
  meteorApplyDevPatches

  # Make sure to generate a clean build, since android seems to bail if the projects were already made
  rm -rf build ../${REPO}-build
  meteor build --debug --directory ../${REPO}-build --server ${DEV_SERVER}/${REPO}

  if [[ -e ../${REPO}-build/bundle ]]
  then
    #This is a weird way to do this.
    rm -rf ${STAGE_DIR}/var/meteor/${REPO}
    mkdir -p ${STAGE_DIR}/var/meteor/${REPO}
    cp -R ../${REPO}-build/bundle/ ${STAGE_DIR}/var/meteor/${REPO}
  fi

  cd ../${REPO}-build

  #find . -name "index.html" -type f -print0 | xargs -0 gsed -i 's#"ROOT_URL":"'"${DEV_SERVER}"'/"#ROOT_URL":"'"${DEV_SERVER}/${REPO}/"'"#g'
  find . -name "index.html" -type f -print0 | xargs -0 gsed -i 's#"ROOT_URL_PATH_PREFIX":""#"ROOT_URL_PATH_PREFIX":"/'"${REPO}"'"#g'
  find . -name "index.html" -type f -print0 | xargs -0 gsed -i 's#"DDP_DEFAULT_CONNECTION_URL":"'"${DEV_SERVER}"'"#"DDP_DEFAULT_CONNECTION_URL":"'"${DEV_SERVER}/${REPO}"'"#g'

  buildIos
  
  if [[ -e ${BUILD_DIR}/${REPO}-build/android/project ]]
  then
    cd ${BUILD_DIR}/${REPO}-build/android/project
    ant debug
    mkdir -p ${STAGE_DIR}/var/www
    cp bin/${REPO}-debug-unaligned.apk ${STAGE_DIR}/var/www/${REPO}.apk
  fi
  
  BUILD_STATUS=$?

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

}

