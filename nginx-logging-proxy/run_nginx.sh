#!/bin/bash

# We define nginx configuration in a bash script in order to have access to environment variables;
# hence, we must not forget to escape nginx $variables in the shell-interpreted `cat` block below.

set -o pipefail -o errexit -o nounset -o xtrace

DEFAULT_LOG_FORMAT='$remote_addr [$time_local] "$request" $status req_time=$request_time body=$request_body'

: ${PROXIED_HOST?'Required env variable'}
: ${PORT?'Required env variable'}
LOG_FORMAT=${LOG_FORMAT:-$DEFAULT_LOG_FORMAT}

# `log_format` reference and available variables:
#  - http://nginx.org/en/docs/http/ngx_http_log_module.html#log_format
#  - https://nginx.org/en/docs/varindex.html
# Note that nginx gives us access to $request_body whereas gunicorn does not
# We redirect access & error logs to /dev/stdout to conform with Docker standards
cat <<EOF >/etc/nginx/nginx.conf
user  nginx;
worker_processes  1;

error_log  /dev/stdout info;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main '$LOG_FORMAT';

    access_log /dev/stdout main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;
    #gzip  on;
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat <<EOF >/etc/nginx/conf.d/default.conf
server {
    listen ${PORT};
    server_name localhost;
    location / {
        proxy_pass http://${PROXIED_HOST}:${PORT};
    }
}
EOF

exec nginx -g 'daemon off;'
