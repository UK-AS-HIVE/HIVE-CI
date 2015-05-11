function generateInitd {
  APPS_DIR="${STAGE_DIR}/var/meteor"
  mkdir -p ${APPS_DIR}
  DIRS=`ls -lU $APPS_DIR | egrep '^d' | awk '{print $9}'`
  PORT=3000

  mkdir -p $STAGE_DIR/etc/init.d/

  for DIR in $DIRS
  do
    cat << EOF > $STAGE_DIR/etc/init.d/meteor-$DIR
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
  export ROOT_URL=${DEV_SERVER}/${DIR}
  export MAIL_URL=smtp://localhost:25
EOF

    if [[ -e "${BUILD_DIR}/${DIR}/settings.json" ]]
    then
      echo "Project ${DIR} includes settings.json, converting to environment variable for deployment"
      SETTINGS=$(cat ${BUILD_DIR}/${DIR}/settings.json | python -c "import json,sys; print json.dumps(sys.stdin.read())[1:-1]")
      echo "  export METEOR_SETTINGS=\$'${SETTINGS}'" >> $STAGE_DIR/etc/init.d/meteor-$DIR
    fi

    cat << EOF >> $STAGE_DIR/etc/init.d/meteor-$DIR

  forever start --pidFile \$pidfile -l \$logFile -o \$outFile -e \$errFile -a -d --sourceDir \$sourceDir/ main.js

  RETVAL=\$?
}

restart() {
  echo -n "Restarting \$scriptId"
  /usr/local/bin/forever restart \$scriptId
  RETVAL=\$?
}

stop() {
  echo -n "Shutting down \$scriptId"
  /usr/local/bin/forever stop \$scriptId
  RETVAL=\$?
}

status() {
  echo -n "Status \$scriptId"
  /usr/local/bin/forever list
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
PORT=$((PORT+1))
done
chmod +x ${STAGE_DIR}/etc/init.d/*
}
