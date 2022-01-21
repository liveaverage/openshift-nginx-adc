# These three ARGs must point to an Iron Bank image - the BASE_REGISTRY should always be what is written below; please use \
# '--build-arg' when building locally to replace these values
# If your container is not based on either the ubi7/ubi8 Iron Bank images, then it should be based on a different Iron Bank image
# Note that you will not be able to pull containers from nexus-docker-secure.levelup-dev.io into your local dev machine 
ARG BASE_REGISTRY=registry.access.redhat.com
ARG BASE_IMAGE=ubi8/ubi-minimal
ARG BASE_TAG=8.4

# FROM statement must reference the base image using the three ARGs established
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

ARG UID=101
ARG GID=101

# If installing packages via a 'microdnf install..', a 'yum/dnf clean all' is important to avoid unnecessary findings in the scans
# Using --nogpgcheck is no longer allowed.  You should also not have to use --disablerepo or --enablerepo flags.  Note that if \
# you are using a ubi base or ubi-derived image, only standard ubi repos are available.  Please visit \
# https://repo1.dsop.io/dsop/redhat/ubi/ubi8/-/blob/development/ironbank.repo for more information.  Contact us if you have \
# issues downloading a package from these repos you believe should be available.

# Update image

RUN microdnf -y clean all \
    && microdnf -y update --nodocs \
    && microdnf -y clean all \
    && rm -rf /var/cache/yum \
    && mkdir /tmp/pkgs

## Install Nginx Plus
# New Line 41 to be added path to the NGINX off-line repo (wget -P /etc/yum.repos.d /nginx-repo/nginx-plus-23-1.el8.ngx.x86_64.rpm && \)
COPY nginx-repo /tmp/pkgs

ARG IMPORTANT_DEPENDENCY=openssl-1.1.1k-1.el8.x86_64.rpm
COPY ["${IMPORTANT_DEPENDENCY}", "/tmp/pkgs"]


RUN rpm -ivh --nodeps /tmp/pkgs/openssl-*.rpm \
    && microdnf install -y shadow-utils tar gzip \
    && rpm -ivh --nodeps /tmp/pkgs/nginx-plus-*.rpm \
    ## Optional: Install NGINX Plus Modules from repo
    # See https://www.nginx.com/products/nginx/modules
    #microdnf install -y --disableplugin=subscription-manager nginx-plus-module-modsecurity && \
    #microdnf install -y --disableplugin=subscription-manager nginx-plus-module-geoip && \
    #microdnf install -y --disableplugin=subscription-manager nginx-plus-module-njs && \
    && rpm -e --nodeps `rpm -qa | grep shadow-utils` \
    && rpm -e --nodeps `rpm -qa | grep libsemanage` \
    && microdnf -y clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /tmp/pkgs

# Optional: COPY over any of your SSL certs in /etc/ssl for HTTPS servers
# e.g.
# COPY etc/ssl   /etc/ssl

# COPY /etc/nginx (Nginx configuration) directory
COPY etc/nginx /etc/nginx

# implement changes required to run NGINX as an unprivileged user
RUN sed -i 's,listen.*80,listen       8080,' /etc/nginx/conf.d/default.conf \
    && sed -i '/user  nginx;/d' /etc/nginx/nginx.conf \
    && sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf \
    && sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf \
# nginx user must own the cache and etc directory to write cache and tweak the nginx config
    && chown -R $UID:0 /var/cache/nginx \
    && chmod -R g+w /var/cache/nginx \
    && chown -R $UID:0 /etc/nginx \
    && chmod -R g+w /etc/nginx


# Check imported NGINX config and set permissions and ownership
RUN nginx -t \
    # Forward request logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    # ln -sf /dev/stdout /var/log/nginx/stream.log \
    # **Remove the Nginx Plus cert/keys from the image**
    # rm /etc/ssl/nginx/nginx-repo.crt /etc/ssl/nginx/nginx-repo.key
    && nginx -T \
    && chown -R $UID:0 /tmp/nginx.pid \
    && chmod -R ugo+rwx /tmp/nginx.pid

EXPOSE 8080

STOPSIGNAL SIGQUIT

USER $UID

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f localhost:8080 || exit 1

CMD ["nginx", "-g", "daemon off;"]
