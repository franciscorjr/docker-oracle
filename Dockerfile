FROM php:7-apache

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY start-apache /usr/local/bin
RUN ["chmod", "+x", "/usr/local/bin/start-apache"]
RUN a2enmod rewrite


# Copy application source
COPY src /var/www/public/
RUN chown -R www-data:www-data /var/www

ARG release=19
ARG update=13

RUN  apt-get install oracle-release-el8 -y && \
     apt-get install oracle-instantclient${release}.${update}-basic oracle-instantclient${release}.${update}-devel oracle-instantclient${release}.${update}-sqlplus -y && \
     rm -rf /var/cache/dnf

CMD ["start-apache"]
