# These three ARGs must point to an Iron Bank image - the BASE_REGISTRY should always be what is written below; please use \
# '--build-arg' when building locally to replace these values
# If your container is not based on either the ubi7/ubi8 Iron Bank images, then it should be based on a different Iron Bank image
# Note that you will not be able to pull containers from nexus-docker-secure.levelup-dev.io into your local dev machine 
ARG BASE_REGISTRY=registry1.dsop.io
ARG BASE_IMAGE=redhat/ubi/ubi8
ARG BASE_TAG=8.2

# FROM statement must reference the base image using the three ARGs established
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

# 'LABEL' instructions should include at least the following information and any other helpful details.
# Labels consumed by Red Hat build service
LABEL Component="nginx" \
      Name="f5networks/nginx-plus-software-adc" \
      Version="1.23.1" \
      Release="1"

# Labels could be consumed by OpenShift
LABEL io.k8s.description="nginx [engine x] is an HTTP and reverse proxy server, a mail proxy server, and a generic TCP/UDP proxy server, originally written by Igor Sysoev." \
      io.k8s.display-name="nginx 1.23.1" \
      io.openshift.expose-services="80:http" \
      io.openshift.tags="nginx"

# If installing packages via a 'yum install..', a 'yum/dnf clean all' is important to avoid unnecessary findings in the scans
# Using --nogpgcheck is no longer allowed.  You should also not have to use --disablerepo or --enablerepo flags.  Note that if \
# you are using a ubi base or ubi-derived image, only standard ubi repos are available.  Please visit \
# https://repo1.dsop.io/dsop/redhat/ubi/ubi8/-/blob/development/ironbank.repo for more information.  Contact us if you have \
# issues downloading a package from these repos you believe should be available.

# Update image

RUN yum update -y && \
    yum -y clean all &&\
    rm -rf /var/cache/yum 

## Install Nginx Plus
# New Line 41 to be added path to the NGINX off-line repo (wget -P /etc/yum.repos.d /nginx-repo/nginx-plus-23-1.el8.ngx.x86_64.rpm && \)
COPY nginx-repo /etc/yum.repos.d

RUN yum install -y ca-certificates openssl && \
    rpm -ihv /etc/yum.repos.d/nginx-plus-23-1.el8.ngx.x86_64.rpm && \
    ## Optional: Install NGINX Plus Modules from repo
    # See https://www.nginx.com/products/nginx/modules
    #yum install -y --disableplugin=subscription-manager nginx-plus-module-modsecurity && \
    #yum install -y --disableplugin=subscription-manager nginx-plus-module-geoip && \
    #yum install -y --disableplugin=subscription-manager nginx-plus-module-njs && \
    rm -rf /var/cache/yum

# Optional: COPY over any of your SSL certs in /etc/ssl for HTTPS servers
# e.g.
# COPY etc/ssl   /etc/ssl

# COPY /etc/nginx (Nginx configuration) directory
COPY etc/nginx /etc/nginx

# Check imported NGINX config
RUN nginx -t && \
    # Forward request logs to docker log collector
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    # ln -sf /dev/stdout /var/log/nginx/stream.log \
    # **Remove the Nginx Plus cert/keys from the image**
    # rm /etc/ssl/nginx/nginx-repo.crt /etc/ssl/nginx/nginx-repo.key
    nginx -T

# EXPOSE ports, HTTP 80, HTTPS 443 and, Nginx status page 8080
EXPOSE 80 443 8080
STOPSIGNAL SIGTERM
HEALTHCHECK --timeout=30s CMD ["nginx", "-g", "daemon off;"]
