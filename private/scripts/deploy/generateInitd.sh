function generateInitd {
  APPS_DIR="${STAGE_DIR}/var/meteor"
  mkdir -p ${APPS_DIR}
  DIRS=`ls -lU $APPS_DIR | egrep '^d' | awk '{print $9}'`
  PORT=${APP_INTERNAL_PORT}

  mkdir -p $STAGE_DIR/etc/init.d/

  INITD_FILE=${STAGE_DIR}/etc/init.d/meteor-${REPO}
  echo "INITD_FILE = ${INITD_FILE}"
  DIR=${REPO}

  cat << EOF > ${INITD_FILE}
#!/bin/bash
#
# description: Script to start a meteor application through forever
# processname: forever/coffeescript/node
# pidfile: /var/log/forever-initd-$DIR.pid
# logfile: /var/log/forever-initd-$DIR.log
#
# Based on a script posted by
# https://github.com/hectorcorrea/hectorcorrea.com/blob/master/etc/forever-initd-hectorcorrea.sh
#
### BEGIN INIT INFO
# Provides:        meteor-$DIR
# Required-Start:  $remote_fs $syslog
# Required-Stop:   $remote_fs $syslog
# Should-Start:    $portmap
# Should-Stop:     $portmap
# X-Start-Before:  nis
# X-Stop-After:    nis
# Default-Start:   2 3 4 5
# Default-Stop:    0 1 6
# X-Interactive:   true
# Short-Description: Meteor app
# Description:     This file should be used to construct scripts to be
#                  placed in /etc/init.d.
### END INIT INFO
pidfile=/var/log/forever-initd-meteor-$DIR.pid
logFile=/var/log/forever-initd-meteor-$DIR.log
errFile=/var/log/forever-initd-meteor-$DIR.err
outFile=/var/log/forever-initd-meteor-$DIR.out

sourceDir=/var/meteor/$DIR
scriptId=\$sourceDir/main.js

setup_nodejs() {
  if [[ ! -d /opt/nvm ]]
  then
    cd /opt/
    git clone https://github.com/creationix/nvm
  fi

  source /opt/nvm/nvm.sh
  nvm install ${NODE_VERSION}
  nvm use ${NODE_VERSION}

  if [[ -z \`which forever\` ]]
  then
    npm install -g --unsafe-perm forever
  fi
  cd /var/meteor/${REPO}/programs/server && npm install
}

start() {
  echo "Starting \$scriptId"

  # This is found in the library referenced at the top of the script
  start_daemon

  cd \$sourceDir

  export PORT=$PORT
  export MONGO_URL=mongodb://localhost:27017/$DIR
  export ROOT_URL=${DEV_SERVER}
  export MAIL_URL=smtp://localhost:25
  ${INITD_ENVVARS}
EOF

  if [[ -e "${BUILD_DIR}/${DIR}/settings.json" ]]
  then
    echo "Project ${DIR} includes settings.json, converting to environment variable for deployment"
    SETTINGS=$(cat ${BUILD_DIR}/${DIR}/settings.json | python -c "import json,sys; print json.dumps(sys.stdin.read())[1:-1]")
    echo "  export METEOR_SETTINGS=\$'${SETTINGS}'" >> ${INITD_FILE}
  fi

  cat << EOF >> ${INITD_FILE}

  setup_nodejs
  forever start --pidFile \$pidfile -l \$logFile -o \$outFile -e \$errFile -a -d --sourceDir \$sourceDir/ main.js

  RETVAL=\$?
}

restart() {
  echo -n "Restarting \$scriptId"
  setup_nodejs
  forever restart \$scriptId
  RETVAL=\$?
}

stop() {
  echo -n "Shutting down \$scriptId"
  setup_nodejs
  forever stop \$scriptId
  RETVAL=\$?
}

status() {
  echo -n "Status \$scriptId"
  setup_nodejs
  forever list
  RETVAL=\$?
}


case "\$1" in
  start)
  start
  ;;
  stop)
  stop
  ;;
  status)
  status
  ;;
  restart)
  restart
  ;;
  *)
  echo "Usage: {start|stop|status|restart}"
  exit 1
  ;;
esac
exit \$RETVAL

EOF
chmod +x ${STAGE_DIR}/etc/init.d/*
}
