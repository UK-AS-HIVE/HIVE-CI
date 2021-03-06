function generateHtmlindex {
  echo "Generating HTML index"

  if [[ -z ${TARGET_APP_PATH} ]]
  then
    return
  fi
  INDEX_PATH=${STAGE_DIR}/var/www${TARGET_APP_PATH}
  mkdir -p ${INDEX_PATH} #${STAGE_DIR}/var/www/${TARGET_APP_PATH}
  PLISTS=`find ${INDEX_PATH} -name "*.plist"`
  if [[ ! -z ${PLISTS} ]]
  then
    PLISTS=`echo ${PLISTS} | grep -o -e "[a-zA-Z0-9_\-]\+\.plist$"`
  fi
  APKS=`find ${INDEX_PATH} -name "*.apk"`
  if [[ ! -z ${APKS} ]]
  then
    APKS=`echo ${APKS} | grep -o -e "[a-zA-Z0-9_\-]\+\.apk$"`
  fi
  DEVSERVER="${TARGET_PROTOCOL}//${TARGET_HOSTNAME}:${TARGET_PORT}${TARGET_APP_PATH}"
  touch ${INDEX_PATH}/index.html
  cat << EOF > ${INDEX_PATH}/index.html
<html>
<body>
EOF

  for APK in ${APKS}
  do
    TIME=$(ls -l ${INDEX_PATH}/${APK} | awk '{print $6,$7,$8}')
    NAME=`basename -s .apk ${APK}`
    echo -e "<h2>${NAME} - ${TIME}</h2>" >> ${INDEX_PATH}/index.html
    echo -e "<a href=\"${DEV_SERVER}\">Web</a><br />" >> ${INDEX_PATH}/index.html
    echo -e "<a href=\"${DEVSERVER}${NAME}.apk\">Android</a><br />" >> ${INDEX_PATH}/index.html
    echo -e "<a href=\"itms-services://?action=download-manifest&url=${DEVSERVER}${NAME}.plist\">iOS App</a><br />" >> ${INDEX_PATH}/index.html 
  done

  cat << EOF >> ${INDEX_PATH}/index.html
</body>
</html>
EOF
}

