FROM cloudron/base:3.0.0@sha256:455c70428723e3a823198c57472785437eb6eab082e79b3ff04ea584faf46e92

RUN mkdir -p /app/code
WORKDIR /app/code

# when external repo is added, apt-get will install the latest in case of conflicting name. apt-cache policy <name> will show what is getting used
# so the remove of 7.4 is probably superfluous but here for completeness
RUN apt-get remove -y php-* php7.4-* libapache2-mod-php7.4 && \
    apt-get autoremove -y && \
    add-apt-repository --yes ppa:ondrej/php && \
    apt update && \
    apt install -y php8.0 php8.0-{apcu,bcmath,bz2,cgi,cli,common,curl,dba,dev,enchant,fpm,gd,gmp,gnupg,imagick,imap,interbase,intl,ldap,mailparse,mbstring,mysql,odbc,opcache,pgsql,phpdbg,pspell,readline,redis,snmp,soap,sqlite3,sybase,tidy,uuid,xml,xmlrpc,xsl,zip,zmq} libapache2-mod-php8.0 && \
    apt install -y php7.4 php7.4-{apcu,bcmath,bz2,cgi,cli,common,curl,dba,dev,enchant,fpm,gd,geoip,gmp,gnupg,imagick,imap,interbase,intl,ldap,mailparse,mbstring,mysql,odbc,opcache,pgsql,phpdbg,pspell,readline,redis,snmp,soap,sqlite3,sybase,tidy,uuid,xml,xmlrpc,xsl,zip,zmq} libapache2-mod-php7.4 && \
    apt install -y php-{date,pear,twig,validate} && \
    rm -rf /var/cache/apt /var/lib/apt/lists

RUN curl --fail -L https://getcomposer.org/download/2.1.8/composer.phar -o /usr/bin/composer && chmod +x /usr/bin/composer

# this binaries are not updated with PHP_VERSION since it's a lot of work. but this is specifically done here for compatibility reasons
# existing 7.4 users might be calling php directly.
RUN update-alternatives --set php /usr/bin/php7.4 && \
    update-alternatives --set phar /usr/bin/phar7.4 && \
    update-alternatives --set phar.phar /usr/bin/phar.phar7.4 && \
    update-alternatives --set phpize /usr/bin/phpize7.4 && \
    update-alternatives --set php-config /usr/bin/php-config7.4

# configure apache
# keep the prefork linking below a2enmod since it removes dangling mods-enabled (!)
# perl kills setlocale() in php - https://bugs.mageia.org/show_bug.cgi?id=25411
RUN a2disconf other-vhosts-access-log && \
    echo "Listen 80" > /etc/apache2/ports.conf && \
    a2enmod rewrite headers rewrite expires cache && \
    a2dismod perl && \
    rm /etc/apache2/sites-enabled/* && \
    sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf && \
    ln -sf /app/data/apache/mpm_prefork.conf /etc/apache2/mods-enabled/mpm_prefork.conf && \
    ln -sf /app/data/apache/app.conf /etc/apache2/sites-enabled/app.conf && \
    rm /etc/apache2/mods-enabled/php*.conf /etc/apache2/mods-enabled/php*.load && \
    ln -sf /run/apache2/php.conf /etc/apache2/mods-enabled/php.conf && \
    ln -sf /run/apache2/php.load /etc/apache2/mods-enabled/php.load

COPY apache/ /app/code/apache/

# configure mod_php
RUN for v in 7.4 8.0; do \
        crudini --set /etc/php/$v/apache2/php.ini PHP upload_max_filesize 64M && \
        crudini --set /etc/php/$v/apache2/php.ini PHP post_max_size 64M && \
        crudini --set /etc/php/$v/apache2/php.ini PHP memory_limit 128M && \
        crudini --set /etc/php/$v/apache2/php.ini opcache opcache.enable 1 && \
        crudini --set /etc/php/$v/apache2/php.ini opcache opcache.enable_cli 1 && \
        crudini --set /etc/php/$v/apache2/php.ini opcache opcache.interned_strings_buffer 8 && \
        crudini --set /etc/php/$v/apache2/php.ini opcache opcache.max_accelerated_files 10000 && \
        crudini --set /etc/php/$v/apache2/php.ini opcache opcache.memory_consumption 128 && \
        crudini --set /etc/php/$v/apache2/php.ini opcache opcache.save_comments 1 && \
        crudini --set /etc/php/$v/apache2/php.ini opcache opcache.validate_timestamps 1 && \
        crudini --set /etc/php/$v/apache2/php.ini opcache opcache.revalidate_freq 60 && \
        crudini --set /etc/php/$v/apache2/php.ini Session session.save_path /run/app/sessions && \
        crudini --set /etc/php/$v/apache2/php.ini Session session.gc_probability 1 && \
        crudini --set /etc/php/$v/apache2/php.ini Session session.gc_divisor 100 ; \
    done

RUN for v in 7.4 8.0; do \
        cp /etc/php/$v/apache2/php.ini /etc/php/$v/cli/php.ini && \
        ln -s /app/data/php.ini /etc/php/$v/apache2/conf.d/99-cloudron.ini && \
        ln -s /app/data/php.ini /etc/php/$v/cli/conf.d/99-cloudron.ini ; \
    done

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
    curl -L https://files.phpmyadmin.net/phpMyAdmin/5.1.1/phpMyAdmin-5.1.1-all-languages.tar.gz | tar zxvf - -C /app/code/phpmyadmin --strip-components=1
COPY phpmyadmin-config.inc.php /app/code/phpmyadmin/config.inc.php

# configure cron
RUN rm -rf /var/spool/cron && ln -s /run/cron /var/spool/cron
# clear out the crontab
RUN rm -f /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/* && truncate -s0 /etc/crontab

# ioncube. the extension dir comes from php -i | grep extension_dir
# extension has to appear first, otherwise will error with "The Loader must appear as the first entry in the php.ini file"
# ioncube does not seem to have support for 8.0 yet
RUN mkdir /tmp/ioncube && \
    curl http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz | tar zxvf - -C /tmp/ioncube && \
    cp /tmp/ioncube/ioncube/ioncube_loader_lin_7.4.so /usr/lib/php/20190902/ && \
    rm -rf /tmp/ioncube && \
    echo "zend_extension=/usr/lib/php/20190902/ioncube_loader_lin_7.4.so" > /etc/php/7.4/apache2/conf.d/00-ioncube.ini && \
    echo "zend_extension=/usr/lib/php/20190902/ioncube_loader_lin_7.4.so" > /etc/php/7.4/cli/conf.d/00-ioncube.ini

# configure supervisor
ADD supervisor/ /etc/supervisor/conf.d/
RUN sed -e 's,^logfile=.*$,logfile=/run/supervisord.log,' -i /etc/supervisor/supervisord.conf

# add code
COPY start.sh index.php crontab.template credentials.template phpmyadmin_login.template /app/code/

# lock www-data but allow su - www-data to work
RUN passwd -l www-data && usermod --shell /bin/bash --home /app/data www-data

CMD [ "/app/code/start.sh" ]
