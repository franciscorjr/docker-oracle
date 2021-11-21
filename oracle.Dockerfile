# Copyright (c) 2020, 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# The oraclelinux8-compat:8-slim image adds microdnf to the oraclelinux:8 image
# so that any automation that relied on microdnf continues to work
FROM ghcr.io/oracle/oraclelinux8-compat:8-slim

RUN dnf -y module enable php:7.4 httpd:2.4 && \
    dnf -y install httpd httpd-filesystem httpd-tools \
           mod_http2 mod_ssl openssl \
           php php-cli php-common php-json php-mbstring php-mysqlnd php-pdo php-xml php-pear php-devel && \
    rm -rf /var/cache/dnf \
    && \
    # Disable event module and enable prefork so that mod_php is enabled
    sed -i 's/#LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/LoadModule mpm_prefork_module modules\/mod_mpm_prefork.so/' /etc/httpd/conf.modules.d/00-mpm.conf && \
    sed -i 's/LoadModule mpm_event_module modules\/mod_mpm_event.so/#LoadModule mpm_event_module modules\/mod_mpm_event.so/' /etc/httpd/conf.modules.d/00-mpm.conf && \
    # Disable HTTP2 as it is not supported with the prefork module
    sed -i 's/LoadModule http2_module modules\/mod_http2.so/#LoadModule http2_module modules\/mod_http2.so/' /etc/httpd/conf.modules.d/10-h2.conf && \
    sed -i 's/LoadModule proxy_http2_module modules\/mod_proxy_http2.so/#LoadModule proxy_http2_module modules\/mod_proxy_http2.so/' /etc/httpd/conf.modules.d/10-proxy_h2.conf \
    && \
    # Create self-signed certificate for mod_ssl
    openssl req -x509 -nodes -newkey rsa:4096 \
                -keyout /etc/pki/tls/private/localhost.key \
                -out /etc/pki/tls/certs/localhost.crt \
                -days 3650 -subj '/CN=localhost' \
    && \
    # Redirect logging to stdout/stderr for container logging to work
    sed -i 's/;error_log = syslog/error_log = \/dev\/stderr/' /etc/php.ini && \
    ln -sf /dev/stdout /var/log/httpd/access_log && \
    ln -sf /dev/stderr /var/log/httpd/error_log && \
    ln -sf /dev/stdout /var/log/httpd/ssl_access_log && \
    ln -sf /dev/stderr /var/log/httpd/ssl_error_log && \
    # Disable userdirs and the auto-generated welcome message
    rm -f /etc/httpd/conf.d/{userdir.conf,welcome.conf}

# Install Oracle Client the last one 21c and sqlplus
RUN dnf -y install oracle-instantclient-release-el8 && \
    dnf -y install oracle-instantclient-basic && \
    dnf -y install oracle-instantclient-devel && \
    dnf -y install oracle-instantclient-sqlplus && \
    dnf -y install make

# Install oci8 extention
RUN pecl install oci8-2.2.0


# Copy application source
COPY src /var/www/html/

# Copy php.ini with extension=oci8.so enabled inside
COPY php.ini /etc/

EXPOSE 80 443

CMD ["/sbin/httpd", "-DFOREGROUND"]
