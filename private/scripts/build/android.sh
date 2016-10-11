function buildAndroid() {

  if [[ -e ${BUILD_DIR}/${REPO}-build/android/project ]]
  then
    cd ${BUILD_DIR}/${REPO}-build/android/project
    #ant debug
    if [[ ! -z ${TARGET_APP_PATH} ]]
    then
      mkdir -p ${STAGE_DIR}/var/www/${TARGET_APP_PATH}
      cp build/outputs/apk/android-debug-unaligned.apk ${STAGE_DIR}/var/www/${TARGET_APP_PATH}/${REPO}.apk
    fi
  fi
}

