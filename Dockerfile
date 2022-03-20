FROM centos:7

ENV NGINX_VERSION=1.21.6

RUN yum install -y curl vim wget tree
RUN yum install -y make gcc pcre-devel openssl-devel gd-devel

WORKDIR /usr/local/src
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O nginx.tar.gz
RUN tar -xzf nginx.tar.gz

RUN wget http://hg.nginx.org/njs/archive/tip.tar.gz -O njs.tar.gz
RUN tar -xzf njs.tar.gz
RUN mv $(find /usr/local/src -name "njs-[0-9a-f]*") njs

WORKDIR /usr/local/src/nginx-${NGINX_VERSION}
RUN ./configure \
    --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-stream \
    --with-http_image_filter_module \
    --with-http_realip_module \
    --with-stream_ssl_module \
    --add-dynamic-module=/usr/local/src/njs/nginx
RUN make
RUN make install

ENV PATH $PATH:/usr/local/nginx/sbin

ENTRYPOINT ["nginx"]

EXPOSE 80

EXPOSE 443

ENTRYPOINT ["nginx", "-g", "daemon off;"]