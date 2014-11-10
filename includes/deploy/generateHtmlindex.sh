#!/bin/bash
function generateHtmlindex {
  PLISTS=$(ls ${STAGE_DIR}/var/www/*.plist | grep -o -e "[a-zA-Z0-9_-]\+\.plist$")
  DEVSERVER='https://meteordev.as.uky.edu'
  mkdir -p ${STAGE_DIR}/var/www
  touch $STAGE_DIR/var/www/index.html
  cat << EOF > ${STAGE_DIR}/var/www/index.html
<html>
<body>
EOF

  for PLIST in $PLISTS
  do
    NAME=`basename -s .plist $PLIST`
    echo -e "<a href=\"$DEVSERVER/$NAME/\">$NAME on the web</a><br />" >> ${STAGE_DIR}/var/www/index.html
    echo -e "<a href=\"itms-services://?action=download-manifest&url=$DEVSERVER/$NAME.plist\">Install $NAME as an iOS app</a><br />" >> ${STAGE_DIR}/var/www/index.html 
  done

  cat << EOF >> ${STAGE_DIR}/var/www/index.html
</body>
</html>
EOF
}
