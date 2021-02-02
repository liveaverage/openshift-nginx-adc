# nginx-plus-Software-ADC

NGINX Plus Docker image for RHEL 8

## What is nginx-Plus

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

 The NGINX-Plus platform can be deployed as Virtual Machine, Container, Bare metal or as a cloud deployment.
> [wikipedia.org/wiki/Nginx](https://en.wikipedia.org/wiki/Nginx)

![logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/nginx/logo.png)

## File Structure

To achieve this separation, we create a configuration layout that supports a multi‑purpose NGINX Plus instance and provides a convenient structure for automating configuration deployment through CI/CD pipelines. The resulting directory structure under `/etc/nginx` looks like this:

...
etc/
├── nginx/
│    ├── conf.d/……………………………………………………………… Subdirectory for other HTTP configurations (Web │server, load balancing, etc.)
│    │   └── default.conf ……………………………
│    ├── includes/ proxy_headers
|    |   └── proxy_headers.conf
│    ├── fastcgi_params
│    ├── koi-utf
│    ├── koi-win
│    ├── mime.types
│    ├── scgi_params
│    ├── uwsgi_params
│    ├── win-utf
│    └── nginx.conf
├──  ssl/
     └── certs/ ………………………………………………………………… /.example.com self signed cert for HTTPS testing
...

## How to use this image

The NGINX-Plus Software ADC image is the F5 base image for the NGINX Platform. No configuration file are included. For how to configure the NGINX-Plus instance please see "https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-plus/". For instuction on unpriveleged install see "https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-plus/#unpriv_install".

## Prerequisites

This should run on a properly subscribed Red Hat Enterprise Linux system (the container will assume the subscription from the OS)

## License Agreement and Documentation

Please find the documentation for NGINX Plus here:
/usr/share/nginx/html/nginx-modules-reference.pdf

NGINX Plus is proprietary software. EULA and License information:
/usr/share/doc/nginx-plus/

For support information, please see:
'https://www.nginx.com/support/'

## Building the Dockerfile

```console
docker build -t nplus-adc-rhel:r.23.1 .


