#!/bin/bash

function generateNginx {
  #Seems like these EOF's have to be not indented, which makes this formatting/indentation a nightmare. Sorry about that.
  APPS_DIR="$STAGE_DIR/var/meteor"
  DIRS=`ls -l $APPS_DIR | egrep '^d' | awk '{print $9}'`
  PORT=3000
  NGINX_DIR="${STAGE_DIR}/etc/nginx/sites-available"
  

  mkdir -p $NGINX_DIR
  touch $NGINX_DIR/meteordev.conf
  cat << EOF > $NGINX_DIR/meteordev.conf
  server {
    listen 80;
    server_name meteordev.as.uky.edu;
    return 301 https://meteordev.as.uky.edu\$request_uri;
  }

  server {
    listen 443;
    server_name meteordev.as.uky.edu
    client_max_body_size 500M;

    access_log /var/log/nginx/meteordev.access.log;
    error_log /var/log/nginx/meteordev.error.log;

    location / {
      root /var/www;
      index index.html;
      try_files \$uri \$uri/ /index.html;
    }
EOF



  for DIR in $DIRS
  do
    cat << EOF >> $NGINX_DIR/meteordev.conf

    location /$DIR/ {
      proxy_pass http://localhost:$PORT;
    }

EOF
    PORT=$((PORT+1))
  done

  cat << EOF >> $NGINX_DIR/meteordev.conf
    proxy_set_header X-Real-IP $remote_addr;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
    proxy_redirect off;

    ssl on;
    ssl_certificate /etc/ssl/certs/sslhost.pem;
    ssl_certificate_key /etc/ssl/private/sslhost.key;

    ssl_verify_depth 3;

    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 5m;
    ssl_protocols SSLv3 TLSv1;
    ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv3:+EXP;
    ssl_prefer_server_ciphers on;
  }

EOF
}
