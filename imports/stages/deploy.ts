//import {Assets} from 'meteor/tools';

export const deploy = {
  name: "Deploying to host",
  cmd: Assets.getText('scripts/deploy/generateInitd.sh') + Assets.getText('scripts/deploy/generateHtmlindex.sh') + "generateInitd\ngenerateHtmlindex\n\necho \"Deploying ${REPO} to ${DEV_SERVER}...\"\ncd ${STAGE_DIR}\nrsync -az -e \"ssh -p ${SSH_PORT} -oBatchMode=yes\" var/www/ ${SSH_USER}@${SSH_HOST}:/var/www\nrsync -az --delete --exclude 'programs/server/node_modules' --exclude 'programs/server/files' -e \"ssh -p ${SSH_PORT} -oBatchmode=yes\" var/meteor/${REPO} ${SSH_USER}@${SSH_HOST}:/var/meteor\nrsync -avz -e \"ssh -p ${SSH_PORT} -oBatchMode=yes\" etc/nginx/sites-enabled/${SSH_HOST}.conf ${SSH_USER}@${SSH_HOST}:/etc/nginx/sites-enabled/${SSH_HOST}.conf\nrsync -avz -e \"ssh -p ${SSH_PORT} -oBatchMode=yes\" etc/init.d/ ${SSH_USER}@${SSH_HOST}:/etc/init.d\n\necho \"Updating server configuration and restarting app\"\nssh -p ${SSH_PORT} -oBatchMode=yes ${SSH_USER}@${SSH_HOST} << ENDSSH\n  update-rc.d meteor-${REPO} defaults\n  /etc/init.d/meteor-${REPO} stop; /etc/init.d/meteor-${REPO} start\n  service nginx restart\nENDSSH"
};
