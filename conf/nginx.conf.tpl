worker_processes 1;
pid /var/run/nginx.pid;

events {
        worker_connections 1024;
        # multi_accept on;
}

http {
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 3000;
        types_hash_max_size 2048;
        server_tokens off;
        port_in_redirect on;

        server_names_hash_bucket_size 128;
        server_name_in_redirect off;

        client_max_body_size 60m;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        send_timeout 30000;
        client_body_timeout   30000;
        client_header_timeout 30000;
        proxy_connect_timeout 30000;
        proxy_send_timeout 30000;
        proxy_read_timeout 30000;


        access_log /logs/access.log;
        error_log /logs/error.log;

        gzip on;
        gzip_disable "msie6";
        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_buffers 16 8k;
        gzip_http_version 1.1;
        gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

        upstream thumbor {
                server localhost:{{ THUMBOR_PORT | default(8000)}};
        }

        server {
                listen {{ PORT | default(80) }} default;
                server_name localhost;

                proxy_set_header Connection "";

                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Allow-Credentials' 'true';
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                add_header 'Access-Control-Allow-Headers' '*';
                add_header 'Access-Control-Expose-Headers' 'Location';

                if ($request_method = 'OPTIONS') {
                    return 204;
                }

                location ~* "^/(..)(..)(.+)?$" {
                    root        /data/result_storage/v2/$1/$2;
                    expires     1M;
                    error_page  404 = @fetch;
                }

                location @fetch {
                    internal;
                    proxy_pass http://thumbor$request_uri;
                }

                location ~ /\.ht { deny  all; }
                location ~ /\.hg { deny  all; }
                location ~ /\.svn { deny  all; }
        }
}