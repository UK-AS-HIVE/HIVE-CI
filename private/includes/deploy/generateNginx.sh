function generateNginx {
  #Seems like these EOF's have to be not indented, which makes this formatting/indentation a nightmare. Sorry about that.
  echo "Generating nginx config"

  APPS_DIR="$STAGE_DIR/var/meteor"
  mkdir -p ${APPS_DIR}
  DIRS=`ls -lU $APPS_DIR | egrep '^d' | awk '{print $9}'`
  NGINX_DIR="${STAGE_DIR}/etc/nginx/sites-available"
  

  mkdir -p $NGINX_DIR
  touch $NGINX_DIR/${TARGET_HOSTNAME}.conf

  cat << EOF > $NGINX_DIR/${TARGET_HOSTNAME}.conf
  server {
    listen 80;
    server_name ${TARGET_HOSTNAME};
EOF

  if [[ ${TARGET_PROTOCOL} == "https:" ]]
  then
  cat << EOF >> $NGINX_DIR/${TARGET_HOSTNAME}.conf
    return 301 https://${TARGET_HOSTNAME}\$request_uri;
  }

  server {
    listen 443;
    server_name ${TARGET_HOSTNAME}
EOF
  fi

  cat << EOF >> $NGINX_DIR/${TARGET_HOSTNAME}.conf
    client_max_body_size 500M;

    access_log /var/log/nginx/${TARGET_HOSTNAME}.access.log;
    error_log /var/log/nginx/${TARGET_HOSTNAME}.error.log;
EOF

  for APP_INDEX in `find ${STAGE_DIR}/var/www -name index.html | gsed -E "s#${STAGE_DIR}##" | cut -b 9- | gsed -E "s/index.html$//"`
  do
    INDEX_PATH=${STAGE_DIR}/var/www/${APP_INDEX}
    cat << EOF >> $NGINX_DIR/${TARGET_HOSTNAME}.conf

    location ${APP_INDEX} {
      root /var/www/;
      index index.html;
      try_files \$uri \$uri/ =404;
    }

EOF
  done

  for DIR in $DIRS
  do
    APP_PATH=`grep ROOT_URL ${STAGE_DIR}/etc/init.d/meteor-${DIR} | gsed -E "s#^.+https?://[^/]+##"`
    APP_PORT=`grep PORT ${STAGE_DIR}/etc/init.d/meteor-${DIR} | gsed -E "s#^.+PORT=##"`
    cat << EOF >> $NGINX_DIR/${TARGET_HOSTNAME}.conf

    location ${APP_PATH} {
      proxy_pass http://localhost:${APP_PORT};
    }

EOF
  done

  cat << EOF >> $NGINX_DIR/${TARGET_HOSTNAME}.conf
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
    proxy_redirect off;
EOF

  if [[ ${TARGET_PROTOCOL} == "https:" ]]
  then
  cat << EOF >> $NGINX_DIR/${TARGET_HOSTNAME}.conf

    ssl on;
    ssl_certificate /etc/ssl/certs/sslhost.pem;
    ssl_certificate_key /etc/ssl/private/sslhost.key;

    ssl_verify_depth 3;

    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 5m;
    ssl_protocols SSLv3 TLSv1;
    ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
    ssl_prefer_server_ciphers on;
EOF
  fi

  cat << EOF >> $NGINX_DIR/${TARGET_HOSTNAME}.conf
  }
EOF


}
