# docker-nginx-with-fancyindex

Compiling `ngx-fancyindex` as nginx dynamic module for use in nginx official docker image.

## build

    sudo docker build -t nginx-fancyindex:1.20.1-alpine --no-cache .

## usage

Add the following statement to the `nginx.conf` to dynamically import the module:

    load_module /usr/local/nginx/modules/ngx_http_fancyindex_module.so;
