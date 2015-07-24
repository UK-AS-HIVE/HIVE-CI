function generateInitd {
  APPS_DIR="${STAGE_DIR}/var/meteor"
  mkdir -p ${APPS_DIR}
  DIRS=`ls -lU $APPS_DIR | egrep '^d' | awk '{print $9}'`
  PORT=3000

  mkdir -p $STAGE_DIR/etc/init.d/

  INITD_FILE=${STAGE_DIR}/etc/init.d/meteor-${REPO}
  echo "INITD_FILE = ${INITD_FILE}"
  if [[ -e ${INITD_FILE} ]]
  then
    PORT=`grep PORT ${INITD_FILE} | grep -o -E "[0-9]+"`
    echo "This project has been deployed before, using port: ${PORT}"
  else
    if [[ "$(ls -A ${STAGE_DIR}/etc/init.d/)" ]]
    then
      PORT=`grep PORT ${STAGE_DIR}/etc/init.d/meteor-* | grep -o -E "[0-9]+" | sort -r | head -n 1`
      PORT=$((PORT+1))
      echo "This is a new project, using port: ${PORT}"
    else
      echo "This is the first project deploying to this server, using port: ${PORT}"
    fi
  fi

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

start() {
  echo "Starting \$scriptId"

  # This is found in the library referenced at the top of the script
  start_daemon

  # Notice that we change the PATH because on reboot
  # the PATH does not include the path to node.
  cd \$sourceDir
  PATH=/usr/local/bin:\$PATH
  export PORT=$PORT
  export MONGO_URL=mongodb://localhost:27017/$DIR
  export ROOT_URL=${DEV_SERVER}
  export MAIL_URL=smtp://localhost:25
EOF

  if [[ -e "${BUILD_DIR}/${DIR}/settings.json" ]]
  then
    echo "Project ${DIR} includes settings.json, converting to environment variable for deployment"
    SETTINGS=$(cat ${BUILD_DIR}/${DIR}/settings.json | python -c "import json,sys; print json.dumps(sys.stdin.read())[1:-1]")
    echo "  export METEOR_SETTINGS=\$'${SETTINGS}'" >> ${INITD_FILE}
  fi

  cat << EOF >> ${INITD_FILE}

  forever start --pidFile \$pidfile -l \$logFile -o \$outFile -e \$errFile -a -d --sourceDir \$sourceDir/ main.js

  RETVAL=\$?
}

restart() {
  echo -n "Restarting \$scriptId"
  forever restart \$scriptId
  RETVAL=\$?
}

stop() {
  echo -n "Shutting down \$scriptId"
  forever stop \$scriptId
  RETVAL=\$?
}

status() {
  echo -n "Status \$scriptId"
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
