WEB_DIR='/var/meteor'
DIRS=`ls -l --time-style="long-iso" $WEB_DIR | egrep '^d' | awk '{print 8}'`
PORT=3000
NGINX_CONF='/etc/nginx/sites-available/meteordev.conf'

touch $NGINX_CONF
cat << EOF > $NGINX_CONF
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
EOF



for DIR in $DIRS
do
  cat << EOF >> $NGINX_CONF

  location /$DIR/ {
    proxy_pass http://localhost:$PORT
  }

EOF
  PORT=$((PORT+10))
done

cat << EOF >> $NGINX_CONF
  proxy_set_header X-Real-IP $remote_addr;
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
  proxy_set_header Host $host;

  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
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