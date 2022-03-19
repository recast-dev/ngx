# ngx

## 安装 nginx

### Linux

```bash
$ sudo yum install yum-utils
$ vim /etc/yum.repos.d/nginx.repo
```

```diff
+[nginx]
+name=nginx repo
+baseurl=http://nginx.org/packages/mainline/centos/7/$basearch/
+gpgcheck=0
+enabled=1
```
