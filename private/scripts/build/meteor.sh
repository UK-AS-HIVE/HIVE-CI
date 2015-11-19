function buildMeteor() {
  cd ${BUILD_DIR}/${REPO}
  echo -e "\033[1mThis is a meteor ${METEOR_VERSION} app, attempting to build Meteor and iOS archives\033[0m"

  # Hack to add private package
  if [[ ! -z `grep hive:accounts-linkblue .meteor/packages` ]]
  then
    mkdir -p packages
    cd packages
    git clone https://${GH_API_TOKEN}:x-oauth-basic@github.com/UK-AS-HIVE/meteor-accounts-linkblue hive:accounts-linkblue
    cd ..
  fi

  if [[ ! -z `grep hive:accounts-ldap .meteor/packages` ]]
  then
    mkdir -p packages
    cd packages
    git clone https://${GH_API_TOKEN}:x-oauth-basic@github.com/UK-AS-HIVE/meteor-accounts-ldap hive:accounts-ldap
    cd ..
  fi

  if [[ ! -z `grep hive:export-csv .meteor/packages` ]]
  then
    mkdir -p packages
    cd packages
    git clone https://github.com/UK-AS-HIVE/meteor-export-csv hive:export-csv
    cd ..
  fi



  meteor add-platform ios
  if [[ -z `grep android .meteor/platforms` ]]
  then
    echo android >> .meteor/platforms
  fi
  meteorApplyDevPatches

  echo "Finished applying dev patches..."

  echo "Making build directory"
  # Make sure to generate a clean build, since android seems to bail if the projects were already made
  rm -rf build ../${REPO}-build
  echo "Building... for devserver ${DEV_SERVER}"
  meteor build --debug --directory ${BUILD_DIR}/${REPO}-build --architecture os.linux.x86_64 --server ${DEV_SERVER}

  RET=$?
  if [[ ${RET} != 0 ]]
  then
    exit ${RET}
  fi

  if [[ -e ${BUILD_DIR}/${REPO}-build/bundle ]]
  then
    #This is a weird way to do this.
    rm -rf ${STAGE_DIR}/var/meteor/${REPO}
    mkdir -p ${STAGE_DIR}/var/meteor/${REPO}
    cp -R ${BUILD_DIR}/${REPO}-build/bundle/ ${STAGE_DIR}/var/meteor/${REPO}
  fi

  cd ${BUILD_DIR}/${REPO}-build

  #find . -name "index.html" -type f -print0 | xargs -0 gsed -i 's#"ROOT_URL":"'"${DEV_SERVER}"'/"#ROOT_URL":"'"${DEV_SERVER}/${REPO}/"'"#g'
  RAW_DEV_SERVER=`echo ${DEV_SERVER} | gsed "s#https\?://##"`
  find . -name "index.html" -type f -print0 | xargs -0 gsed -i 's#%22ROOT_URL_PATH_PREFIX%22%3A%22%22#%22ROOT_URL_PATH_PREFIX%22%3A%22'"${URIENC_TARGET_PATH}"'%22#g'
  find . -name "index.html" -type f -print0 | xargs -0 gsed -i 's#%22DDP_DEFAULT_CONNECTION_URL%22%3A%22'"${URIENC_TARGET_PROTOCOL}"'%2F%2F'"${URIENC_TARGET_HOSTNAME}"'%22#%22DDP_DEFAULT_CONNECTION_URL%22%3A%22'"${URIENC_TARGET_PROTOCOL}"'%2F%2F'"${URIENC_TARGET_HOSTNAME}%2F${URIENC_TARGET_PATH}"'%22#g'
}

# Execute from within the main directory before building
function meteorApplyDevPatches() {
  echo "Patching html href and src attributes for relative routes"
  find . -depth 1 -name "*.html" | xargs gsed -i 's/href="\//href="{{rootAppUrl}}\//g'
  find . -depth 1 -name "*.html" | xargs gsed -i 's/src="\//src="{{rootAppUrl}}\//g'
  find client -name "*.html" -type f -print0 | xargs -0 gsed -i 's/href="\//href="{{rootAppUrl}}\//g'
  find client -name "*.html" -type f -print0 | xargs -0 gsed -i 's/src="\//src="{{rootAppUrl}}\//g'

  echo "Patching css url() references for relative routes"
  find client -name "*.css" -type f -print0 | xargs -0 gsed -i "s/url(\(['\"]\)\?\(\/\)\?/url(\1\2${REPO}\//g"

  echo "Copying ${ORIG_DIR}/scripts/build/relativeRoutes.js"
  mkdir -p lib/relativeRoutes
  cp ${ORIG_DIR}/scripts/build/relativeRoutes.js lib/relativeRoutes/relativeRoutes.js
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

