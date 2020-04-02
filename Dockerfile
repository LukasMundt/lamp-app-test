FROM cloudron/base:1.0.0@sha256:147a648a068a2e746644746bbfb42eb7a50d682437cead3c67c933c546357617

RUN mkdir -p /app/code
WORKDIR /app/code

# keep composer at the end since it installs cli and chooses 7.4 as the alternative if in the front
RUN apt remove -y php* && \
    add-apt-repository -y ppa:ondrej/php && apt-get update -y && \
    apt-get install -y php7.3 libapache2-mod-php7.3 crudini \
    php7.3-redis \
    php7.3-apcu \
    php7.3-bcmath \
    php7.3-bz2 \
    php7.3-curl \
    php7.3-dba \
    php7.3-enchant \
    php7.3-gd \
    php7.3-geoip \
    php7.3-gettext \
    php7.3-imagick \
    php7.3-imap \
    php7.3-intl \
    php7.3-json \
    php7.3-ldap \
    php7.3-mbstring \
    php7.3-mysql \
    php7.3-pgsql \
    php7.3-readline \
    php7.3-soap \
    php7.3-sqlite3 \
    php7.3-tidy \
    php7.3-uuid \
    php7.3-xml \
    php7.3-zip \
    cron \
    apache2-dev \
    build-essential && \
    apt install -y composer && \
    rm -rf /var/cache/apt /var/lib/apt/lists /etc/ssh_host_*

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
COPY apache/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf
COPY apache/lamp.conf /etc/apache2/sites-enabled/lamp.conf
RUN echo "Listen 80" > /etc/apache2/ports.conf
RUN a2disconf other-vhosts-access-log
RUN a2enmod rewrite headers rewrite expires cache

# configure mod_php
RUN crudini --set /etc/php/7.3/apache2/php.ini PHP upload_max_filesize 64M && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP post_max_size 64M && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP memory_limit 128M && \
    crudini --set /etc/php/7.3/apache2/php.ini Session session.save_path /run/app/sessions && \
    crudini --set /etc/php/7.3/apache2/php.ini Session session.gc_probability 1 && \
    crudini --set /etc/php/7.3/apache2/php.ini Session session.gc_divisor 100

RUN mv /etc/php/7.3/apache2/php.ini /etc/php/7.3/apache2/php.ini.orig && ln -sf /app/data/php.ini /etc/php/7.3/apache2/php.ini

# install RPAF module to override HTTPS, SERVER_PORT, HTTP_HOST based on reverse proxy headers
# https://www.digitalocean.com/community/tutorials/how-to-configure-nginx-as-a-web-server-and-reverse-proxy-for-apache-on-one-ubuntu-16-04-server
RUN mkdir /app/code/rpaf && \
    curl -L https://github.com/gnif/mod_rpaf/tarball/669c3d2ba72228134ae5832c8cf908d11ecdd770 | tar -C /app/code/rpaf -xz --strip-components 1 -f -  && \
    cd /app/code/rpaf && \
    make && \
    make install && \
    rm -rf /app/code/rpaf

# configure rpaf
RUN echo "LoadModule rpaf_module /usr/lib/apache2/modules/mod_rpaf.so" > /etc/apache2/mods-available/rpaf.load && a2enmod rpaf

# phpMyAdmin
RUN mkdir -p /app/code/phpmyadmin && \
    curl -L https://files.phpmyadmin.net/phpMyAdmin/4.9.4/phpMyAdmin-4.9.4-all-languages.tar.gz | tar zxvf - -C /app/code/phpmyadmin --strip-components=1
COPY phpmyadmin-config.inc.php /app/code/phpmyadmin/config.inc.php

# configure cron
RUN rm -rf /var/spool/cron && ln -s /run/cron /var/spool/cron
# clear out the crontab
RUN rm -f /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/* && truncate -s0 /etc/crontab

# ioncube. the extension dir comes from php -i | grep extension_dir
# extension has to appear first, otherwise will error with "The Loader must appear as the first entry in the php.ini file"
RUN mkdir /tmp/ioncube && \
    curl http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz | tar zxvf - -C /tmp/ioncube && \
    cp /tmp/ioncube/ioncube/ioncube_loader_lin_7.3.so /usr/lib/php/20170718 && \
    rm -rf /tmp/ioncube && \
    echo "zend_extension=/usr/lib/php/20170718/ioncube_loader_lin_7.3.so" > /etc/php/7.3/apache2/conf.d/00-ioncube.ini && \
    echo "zend_extension=/usr/lib/php/20170718/ioncube_loader_lin_7.3.so" > /etc/php/7.3/cli/conf.d/00-ioncube.ini

# configure supervisor
ADD supervisor/ /etc/supervisor/conf.d/
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

# add code
COPY start.sh index.php crontab.template credentials.template phpmyadmin_login.template /app/code/

# lock www-data but allow su - www-data to work
RUN passwd -l www-data && usermod --shell /bin/bash --home /app/data www-data

# make cloudron exec sane
WORKDIR /app/data

CMD [ "/app/code/start.sh" ]
