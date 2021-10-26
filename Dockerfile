ARG TAG=1.20.1-alpine

# BUILD Stage
FROM nginx:${TAG} AS builder

# nginx:${TAG} contains NGINX_VERSION environment variable, like so:
# ENV NGINX_VERSION 1.20.1

ENV FANCYINDEX_VERSION 0.5.1

RUN curl "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz && \
    curl -L "https://github.com/aperezdc/ngx-fancyindex/archive/v${FANCYINDEX_VERSION}.tar.gz" -o ngx-fancyindex.tar.gz

# For latest build deps, see https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
    apk add --no-cache --virtual .build-deps \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    libedit-dev \
    mercurial \
    bash \
    alpine-sdk \
    findutils

# Reuse same cli arguments as the nginx:${TAG} image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    CONFARGS=${CONFARGS/-Os -fomit-frame-pointer/-Os} && \
    mkdir /usr/src && \
    tar -zxC /usr/src -f nginx.tar.gz && \
    tar -xzvf "ngx-fancyindex.tar.gz" && \
    FANCYINDEXDIR="$(pwd)/ngx-fancyindex-${FANCYINDEX_VERSION}" && \
    cd /usr/src/nginx-$NGINX_VERSION && \
    sh -c "./configure --with-compat $CONFARGS --add-dynamic-module=$FANCYINDEXDIR" && \
    make modules && \
    mkdir /objs && \
    mv ./objs/*.so /objs/


# DIST Stage
FROM nginx:${TAG}

# Extract the dynamic module ${FANCYINDEX_MOD} from the builder image
ARG FANCYINDEX_MOD=ngx_http_fancyindex_module.so
COPY --from=builder /objs/${FANCYINDEX_MOD} /usr/local/nginx/modules/${FANCYINDEX_MOD}

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# The Nginx parent Docker image already expose port 80, so we only need to add port 443 here.
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]