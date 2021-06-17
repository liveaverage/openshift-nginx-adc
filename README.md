# NGINX-Plus-Software-ADC

## Software Trial and Registration

This software is made available for you at no cost for 60 days.  After that time you are expected to register this software and work with an NGINX Sales representative for ongoing demo licenses or software and support acquisition.

## Register for a Free Gift, Training and Deployment Guides

Register at:  [NGINX Registration Page](https://carah.io/nginxregistration)

Alternatively contact F5 Federal Sales at:  [nginx-federal@f5.com](nginx-federal@f5.com) 

NGINX Plus Docker image for RHEL 8

## What is NGINX-Plus

NGINX Plus is a software load balancer, web server, and content cache built on top of open source NGINX. NGINX Plus has exclusive enterprise‑grade features beyond what's available in the open source offering, including.

- Session persistence
- Enterprise class visibility with 90+ additional metrics and live dashboard built-in
- WAF (OWASP top 10 and/or advanced protection)
- JWT Authentication (simple integration with okta/ping/etc)
- Native OpenID Connect support
- Active health checks on status codeand response body
- Key value store (dynamic IP black-listing,blue/green deployments)
- High Availability / Zone Sync across cluster
- Dynamic reconfiguration—zero downtime
- Service discovery using DNS
- Sticky Session persistence based on cookies

 The NGINX-Plus platform can be deployed as a Virtual Machine, Container, Bare metal or as a cloud deployment.
> [wikipedia.org/wiki/Nginx](https://en.wikipedia.org/wiki/Nginx)

![logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/nginx/logo.png)

## File Structure

To achieve this separation, we create a configuration layout that supports a multi‑purpose NGINX Plus instance and provides a convenient structure for automating configuration deployment through CI/CD pipelines. The resulting directory structure under `/etc/nginx` looks like this:

```console
etc/
├── nginx/
│    ├── conf.d/ ....................... Subdirectory for other HTTP configurations (Web │server, load balancing, etc.)
│    │   └── default.conf .............. Default configuration file
│    └── nginx.conf .................... Main NGINX configuration file
└── ssl/
    └── nginx/ ......................... NGINX Plus repo.crt and repo.key goes here

```

## How to use this image

The NGINX-Plus Software ADC image is the F5 base image for the NGINX Platform. No configuration files are included.

- For how to configure the NGINX-Plus instance please see https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-plus/.
- For instructions on unprivileged install see https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-plus/#unpriv_install.

## Prerequisites

This Container image should be run on a properly subscribed Red Hat Enterprise Linux system (the container will assume the subscription from the OS)

## License Agreement and Documentation

Please find the documentation for NGINX Plus here:
/usr/share/nginx/html/nginx-modules-reference.pdf

NGINX Plus is proprietary software. EULA and License information:
/usr/share/doc/nginx-plus/

For support information, please see:
'https://www.nginx.com/support/'

### Building the Dockerfile

```console
docker build -t nplus-adc-ubi:r.24.2 .

```

### Running the Image

```console
# Run with the default NGINX sample page:
docker run --name nginx -p 8080:8080 --rm -it nplus-adc-ubi:r.24.2

# Run with volume mount overriding default NGINX sample page:
docker run --name nginx -p 8080:8080 --rm -v `pwd`/example:/usr/share/nginx/html -it nplus-adc-ubi:r.24.2
```

## Example Configurations

> Custom configurations are placed in the /etc/nginx/conf.d directory. During Initial build of the container a default.conf file will be created. If using custom configurations the default.conf can be deleted or prior to building the container the following lines can added to the Dockerfile to remove the default.conf and copy all custom configuration to the /etc/nginx/conf.d directory

```console

# Copy Configuration file nginx.conf delete the default.conf file
RUN rm /etc/nginx/conf.d/default.conf
COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY etc/nginx/conf.d /etc/nginx/conf.d

```

### Example loadbalancer Configuration

```console

user       www www;  ## Default: nobody
worker_processes  5;  ## Default: 1
error_log  logs/error.log;
pid        logs/nginx.pid;
worker_rlimit_nofile 8192;

events {
  worker_connections  4096;  ## Default: 1024
}

http {
  include    conf/mime.types;
  include    /etc/nginx/proxy.conf;
  include    /etc/nginx/fastcgi.conf;
  index    index.html index.htm index.php;

  default_type application/octet-stream;
  log_format   main '$remote_addr - $remote_user [$time_local]  $status '
    '"$request" $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
  access_log   logs/access.log  main;
  sendfile     on;
  tcp_nopush   on;
  server_names_hash_bucket_size 128; # this seems to be required for some vhosts

  server { # php/fastcgi
    listen       8080;
    server_name  domain1.com www.domain1.com;
    access_log   logs/domain1.access.log  main;
    root         html;

    location ~ \.php$ {
      fastcgi_pass   127.0.0.1:1025;
    }
  }

  server { # simple reverse-proxy
    listen       80;
    server_name  domain2.com www.domain2.com;
    access_log   logs/domain2.access.log  main;

    # serve static files
    location ~ ^/(images|javascript|js|css|flash|media|static)/  {
      root    /var/www/virtual/big.server.com/htdocs;
      expires 30d;
    }

    # pass requests for dynamic content to rails/turbogears/zope, et al
    location / {
      proxy_pass      http://127.0.0.1:8080;
    }
  }

  upstream big_server_com {
    server 127.0.0.3:8000 weight=5;
    server 127.0.0.3:8001 weight=5;
    server 192.168.0.1:8000;
    server 192.168.0.1:8001;
  }
 
    # simple load balancing
  server { 
    listen          80;
    server_name     big.server.com;
    access_log      logs/big.server.access.log main;

    location / {
      proxy_pass      http://big_server_com;
    }
  }
}

```

### Example Secure dashboard api configuration to enable the NGINX+ Dashboards

```console

Server {

    #listen       8080 default_server;
    listen       8443 ssl;

    server_name  localhost;
     
     ssl_certificate /etc/ssl/certs/server.crt;
     ssl_certificate_key /etc/ssl/private/server.key;
     status_zone status_page;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
 
    #error_page  404              /404.html;
 
    #redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    
    location = /50x.html {
        root   /usr/share/nginx/html;
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
    
    # enable /api/ location with appropriate access control in order
    # to make use of NGINX Plus API
    #
    location /api/ {
         api write=on;
         #allow 127.0.0.1;
         #deny all;
    }
   
    # enable NGINX Plus Dashboard; requires /api/ location to be
    # enabled and appropriate access control for remote access
    #
    location = /dashboard.html {
         root /usr/share/nginx/html;
         auth_basic           "Nginx Pluse Monitoring";
         auth_basic_user_file /etc/nginx/.htpasswd;
    }
}

```

### Simple Loadbalancer Configuration

```console

upstream any-net {
    zone hcheck 64k;
    server 192.168.1.91:80;
    server 192.168.1.96:80;
    server 192.168.1.97:80;
    server 192.168.1.98:80;
}

server {
    listen 443 ssl;
    server_name any-net.com;

    ssl_certificate /etc/ssl/certs/server.crt;
    ssl_certificate_key /etc/ssl/certs/server.key;

location / {
    proxy_pass http://any-net;
    health_check;
    }
```
