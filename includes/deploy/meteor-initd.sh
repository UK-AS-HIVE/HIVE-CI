#!/bin/bash

STAGE_DIR='/Users/digipak/Desktop/HIVE-ci/sandbox/build'
APPS_DIR='${STAGE_DIR}/var/meteor'
DIRS=`ls -l $APPS_DIR | egrep '^d' | awk '{print $9}'`
PORT=3000

mkdir -p init.d/

for DIR in $DIRS
do
  cat << EOF > $STAGE_DIR/etc/initd/meteor-$DIR
#!/bin/bash
#
# description: Script to start a meteor application through forever
# processname: forever/coffeescript/node
# pidfile: /var/run/forever-initd-$DIR.pid
# logfile: /var/run/forever-initd-$DIR.log
#
# Based on a script posted by
# https://github.com/hectorcorrea/hectorcorrea.com/blob/master/etc/forever-initd-hectorcorrea.sh
#
### BEGIN INIT INFO
# Provides:      	meteor-$DIR
# Required-Start:	$remote_fs $syslog
# Required-Stop: 	$remote_fs $syslog
# Should-Start:  	$portmap
# Should-Stop:   	$portmap
# X-Start-Before:	nis
# X-Stop-After:  	nis
# Default-Start: 	2 3 4 5
# Default-Stop:  	0 1 6
# X-Interactive: 	true
# Short-Description: Meteor app
# Description:   	This file should be used to construct scripts to be
#                	placed in /etc/init.d.
### END INIT INFO
pidfile=/var/run/forever-initd-meteor-$DIR.pid
logFile=/var/run/forever-initd-meteor-$DIR.log
errFile=/var/run/forever-initd-meteor-$DIR.err
outFile=/var/run/forever-initd-meteor-$DIR.out

sourceDir=/var/meteor/$DIR
scriptId=$sourceDir/main.js

start() {
	echo "Starting $scriptId"

	# This is found in the library referenced at the top of the script
	start_daemon

	# Notice that we change the PATH because on reboot
	# the PATH does not include the path to node.
	cd $sourceDir
	PATH=/usr/local/bin:$PATH
	PORT=$PORT
MONGO_URL=mongodb://localhost:27017/$DIR
ROOT_URL=http://$DIR.as.uky.edu
MAIL_URL=smtp://localhost:25

forever start --pidFile $pidfile -l $logFile -o $outFile -e $errFile -a -d --sourceDir $sourceDir/ main.js

	RETVAL=$?
}

restart() {
	echo -n "Restarting $scriptId"
	/usr/local/bin/forever restart $scriptId
	RETVAL=$?
}

stop() {
	echo -n "Shutting down $scriptId"
	/usr/local/bin/forever stop $scriptId
	RETVAL=$?
}

status() {
	echo -n "Status $scriptId"
	/usr/local/bin/forever list
	RETVAL=$?
}


case "$1" in
	start)
    	start
find     	;;
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
exit $RETVAL

EOF
done
PORT=$((PORT+1))
