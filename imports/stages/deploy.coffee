exports.deploy =
  name: "Deploying to host"
  cmd:
    Assets.getText('scripts/deploy/generateInitd.sh') +
    Assets.getText('scripts/deploy/generateHtmlindex.sh') +
    """
      generateInitd
      generateHtmlindex

      echo "Deploying ${REPO} to ${DEV_SERVER}..."
      cd ${STAGE_DIR}
      rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" var/www/ ${SSH_USER}@${SSH_HOST}:/var/www
      rsync -avz --delete --exclude 'programs/server/node_modules' --exclude 'programs/server/files' -e "ssh -p ${SSH_PORT} -oBatchmode=yes" var/meteor/${REPO} ${SSH_USER}@${SSH_HOST}:/var/meteor
      rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" etc/nginx/sites-enabled/${SSH_HOST}.conf ${SSH_USER}@${SSH_HOST}:/etc/nginx/sites-enabled/${SSH_HOST}.conf
      rsync -avz -e "ssh -p ${SSH_PORT} -oBatchMode=yes" etc/init.d/ ${SSH_USER}@${SSH_HOST}:/etc/init.d

      echo "Adding meteor-${REPO} to default runlevel and restarting"
      ssh -p ${SSH_PORT} -oBatchMode=yes ${SSH_USER}@${SSH_HOST} << ENDSSH
        #rm /etc/nginx/sites-enabled/*
        #ln -s /etc/nginx/sites-available/${SSH_HOST}.conf /etc/nginx/sites-enabled/${SSH_HOST}.conf
        cd /var/meteor/${REPO}/programs/server && npm install
        update-rc.d meteor-${REPO} defaults
        /etc/init.d/meteor-${REPO} stop; /etc/init.d/meteor-${REPO} start
        service nginx restart
ENDSSH
    """
