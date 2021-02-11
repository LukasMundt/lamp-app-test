FROM cloudron/base:3.0.0@sha256:455c70428723e3a823198c57472785437eb6eab082e79b3ff04ea584faf46e92

RUN mkdir -p /app/code
WORKDIR /app/code

# configure apache
# keep the prefork linking below a2enmod since it removes dangling mods-enabled (!)
RUN a2disconf other-vhosts-access-log && \
    echo "Listen 80" > /etc/apache2/ports.conf && \
    a2enmod rewrite headers rewrite expires cache php7.4 && \
    rm /etc/apache2/sites-enabled/* && \
    sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf && \
    ln -sf /app/data/apache/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf && \
    ln -sf /app/data/apache/app.conf /etc/apache2/sites-enabled/app.conf

COPY apache/ /app/code/apache/

# configure mod_php
RUN crudini --set /etc/php/7.4/apache2/php.ini PHP upload_max_filesize 64M && \
    crudini --set /etc/php/7.4/apache2/php.ini PHP post_max_size 64M && \
    crudini --set /etc/php/7.4/apache2/php.ini PHP memory_limit 128M && \
    crudini --set /etc/php/7.4/apache2/php.ini Session session.save_path /run/app/sessions && \
    crudini --set /etc/php/7.4/apache2/php.ini Session session.gc_probability 1 && \
    crudini --set /etc/php/7.4/apache2/php.ini Session session.gc_divisor 100

RUN cp /etc/php/7.4/apache2/php.ini /etc/php/7.4/cli/php.ini

RUN ln -s /app/data/php.ini /etc/php/7.4/apache2/conf.d/99-cloudron.ini && \
    ln -s /app/data/php.ini /etc/php/7.4/cli/conf.d/99-cloudron.ini

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
    curl -L https://files.phpmyadmin.net/phpMyAdmin/5.0.4/phpMyAdmin-5.0.4-all-languages.tar.gz | tar zxvf - -C /app/code/phpmyadmin --strip-components=1
COPY phpmyadmin-config.inc.php /app/code/phpmyadmin/config.inc.php

# configure cron
RUN rm -rf /var/spool/cron && ln -s /run/cron /var/spool/cron
# clear out the crontab
RUN rm -f /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/* && truncate -s0 /etc/crontab

# ioncube. the extension dir comes from php -i | grep extension_dir
# extension has to appear first, otherwise will error with "The Loader must appear as the first entry in the php.ini file"
RUN mkdir /tmp/ioncube && \
    curl http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz | tar zxvf - -C /tmp/ioncube && \
    cp /tmp/ioncube/ioncube/ioncube_loader_lin_7.4.so /usr/lib/php/20190902/ && \
    rm -rf /tmp/ioncube && \
    echo "zend_extension=/usr/lib/php/20170718/ioncube_loader_lin_7.4.so" > /etc/php/7.4/apache2/conf.d/00-ioncube.ini && \
    echo "zend_extension=/usr/lib/php/20170718/ioncube_loader_lin_7.4.so" > /etc/php/7.4/cli/conf.d/00-ioncube.ini

# configure supervisor
ADD supervisor/ /etc/supervisor/conf.d/
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

# add code
COPY start.sh index.php crontab.template credentials.template phpmyadmin_login.template /app/code/

# lock www-data but allow su - www-data to work
RUN passwd -l www-data && usermod --shell /bin/bash --home /app/data www-data

CMD [ "/app/code/start.sh" ]
