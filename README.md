## 目录

- [编译安装](./docs/编译安装.md)
- [容器化部署](#容器化部署)
  - [Docker](#Docker)
  - [Dockerfile](#Dockerfile)
  - [docker-compose.yml](#docker-compose.yml)
- [常用命令](#常用命令)
- [配置解析](#配置解析)
  - [文件目录](#文件目录)
  - [默认配置](#默认配置)
- [语法高亮](./docs/语法高亮.md)

## 容器化部署

### Docker

```bash
# 安装 yum 工具
$ yum install -y yum-utils

# 安装 Docker 官方 yum 源
$ yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装 Docker 及 docker-compose 应用
$ yum install -y docker-ce docker-compose

# 设置 Docker 服务开机自启动
$ systemctl enable docker

# 启动 Docker 服务
$ systemctl start docker
```

#### 镜像加速器

查看是否在 `docker.service` 文件中配置过镜像地址。

```bash
$ systemctl cat docker | grep '\-\-registry\-mirror'
```

若该命令有输出，则执行 `$ systemctl cat docker` 命令以查看 `ExecStart=` 出现的位置，并修改对应的文件内容去掉 `--registry-mirror` 参数及其值。

```bash
$ vim /etc/docker/daemon.json
```

```diff
+{
+  "registry-mirrors": [
+    "https://hub-mirror.c.163.com",
+    "https://mirror.baidubce.com"
+  ]
+}
```

重启服务:

```bash
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

检查加速器是否生效:

```bash
$ docker info
Registry Mirrors:
  https://hub-mirror.c.163.com/
  https://mirror.baidubce.com/
```

### Dockerfile

```dockerfile
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
```

### docker-compose.yml

```yaml
version: '3'

services:
  nginx:
    build:
      context: ./
      dockerfile: Dockerfile
    container_name: nginx
    image: nginx:latest
    restart: always
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./nginx.conf:/usr/local/nginx/conf/nginx.conf
```

## 常用命令

```bash
[root@fa70ebac0dfb nginx-1.21.6]# nginx -h
nginx version: nginx/1.21.6
Usage: nginx [-?hvVtTq] [-s signal] [-p prefix]
             [-e filename] [-c filename] [-g directives]

Options:
  -?,-h         : this help
  -v            : show version and exit
  -V            : show version and configure options then exit
  -t            : test configuration and exit
  -T            : test configuration, dump it and exit
  -q            : suppress non-error messages during configuration testing
  -s signal     : send signal to a master process: stop, quit, reopen, reload
  -p prefix     : set prefix path (default: /usr/local/nginx/)
  -e filename   : set error log file (default: logs/error.log)
  -c filename   : set configuration file (default: conf/nginx.conf)
  -g directives : set global directives out of configuration file
```

```bash
$ nginx               启动服务
$ nginx -h            查看帮助
$ nginx -v            查看版本
$ nginx -V            查看版本和编译参数
$ nginx -t            检查配置文件语法
$ nginx -T            检查配置文件语法, 并显示配置文件
$ nginx -q            检查配置文件语法, 只显示错误信息
$ nginx -c filename   指定配置文件
$ nginx -s stop       立即停止服务
$ nginx -s quit       平滑停止服务
$ nginx -s reload     平滑重启服务
```

## 配置解析

### 文件目录

Nginx 默认配置目录: `/usr/local/nginx/conf`

Nginx 默认配置文件: `nginx.conf`

```bash
$ # tree -L 1
.
|-- fastcgi.conf # FastCGI 代理服务, 变量传递配置。
|-- fastcgi.conf.default # 样例文件
|-- fastcgi_params # FastCGI 代理服务, 变量传递配置。
|-- fastcgi_params.default # 样例文件
|-- koi-utf # KOI8-R 编码转换的映射文件
|-- koi-win # KOI8-R 编码转换的映射文件
|-- mime.types # MIME 类型映射表
|-- mime.types.default # 样例文件
|-- nginx.conf # Nginx 默认配置入口文件
|-- nginx.conf.default # 样例文件
|-- scgi_params # SCGI 代理服务, 变量传递配置。
|-- scgi_params.default # 样例文件
|-- uwsgi_params # uWSGI 代理服务, 变量传递配置。
|-- uwsgi_params.default # 样例文件
`-- win-utf # KOI8-R 编码转换的映射文件
```

### 默认配置

```bash
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
```
