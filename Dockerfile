FROM cloudron/base:4.2.0@sha256:46da2fffb36353ef714f97ae8e962bd2c212ca091108d768ba473078319a47f4

RUN mkdir -p /app/code
WORKDIR /app/code

# when external repo is added, apt-get will install the latest in case of conflicting name. apt-cache policy <name> will show what is getting used
# so the remove of 7.4 is probably superfluous but here for completeness
RUN apt-get remove -y php-* php7.4-* libapache2-mod-php7.4 && \
    apt-get autoremove -y && \
    add-apt-repository --yes ppa:ondrej/php && \
    apt update && \
    apt install -y php8.2 php8.2-{apcu,bcmath,bz2,cgi,cli,common,curl,dba,dev,enchant,fpm,gd,gmp,gnupg,imagick,imap,interbase,intl,ldap,mailparse,mbstring,mysql,odbc,opcache,pgsql,phpdbg,pspell,readline,redis,snmp,soap,sqlite3,sybase,tidy,uuid,xml,xmlrpc,xsl,zip,zmq} libapache2-mod-php8.2 && \
    apt install -y php8.1 php8.1-{apcu,bcmath,bz2,cgi,cli,common,curl,dba,dev,enchant,fpm,gd,gmp,gnupg,imagick,imap,interbase,intl,ldap,mailparse,mbstring,mysql,odbc,opcache,pgsql,phpdbg,pspell,readline,redis,snmp,soap,sqlite3,sybase,tidy,uuid,xml,xmlrpc,xsl,zip,zmq} libapache2-mod-php8.1 && \
    apt install -y php8.0 php8.0-{apcu,bcmath,bz2,cgi,cli,common,curl,dba,dev,enchant,fpm,gd,gmp,gnupg,imagick,imap,interbase,intl,ldap,mailparse,mbstring,mysql,odbc,opcache,pgsql,phpdbg,pspell,readline,redis,snmp,soap,sqlite3,sybase,tidy,uuid,xml,xmlrpc,xsl,zip,zmq} libapache2-mod-php8.0 && \
    apt install -y php7.4 php7.4-{apcu,bcmath,bz2,cgi,cli,common,curl,dba,dev,enchant,fpm,gd,geoip,gmp,gnupg,imagick,imap,interbase,intl,ldap,mailparse,mbstring,mysql,odbc,opcache,pgsql,phpdbg,pspell,readline,redis,snmp,soap,sqlite3,sybase,tidy,uuid,xml,xmlrpc,xsl,zip,zmq} libapache2-mod-php7.4 && \
    apt install -y php-{date,pear,twig,validate} && \
    rm -rf /var/cache/apt /var/lib/apt/lists

# https://getcomposer.org/download/
RUN curl --fail -L https://getcomposer.org/download/2.6.5/composer.phar -o /usr/bin/composer && chmod +x /usr/bin/composer

# this binaries are not updated with PHP_VERSION since it's a lot of work
RUN update-alternatives --set php /usr/bin/php8.1 && \
    update-alternatives --set phar /usr/bin/phar8.1 && \
    update-alternatives --set phar.phar /usr/bin/phar.phar8.1 && \
    update-alternatives --set phpize /usr/bin/phpize8.1 && \
    update-alternatives --set php-config /usr/bin/php-config8.1

# configure apache
# keep the prefork linking below a2enmod since it removes dangling mods-enabled (!)
# perl kills setlocale() in php - https://bugs.mageia.org/show_bug.cgi?id=25411
RUN a2disconf other-vhosts-access-log && \
    echo "Listen 80" > /etc/apache2/ports.conf && \
    a2enmod rewrite headers rewrite expires cache ldap authnz_ldap proxy proxy_http proxy_wstunnel && \
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
RUN for v in 7.4 8.0 8.1 8.2; do \
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

RUN for v in 7.4 8.0 8.1 8.2; do \
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

# phpMyAdmin (https://www.phpmyadmin.net/files/)
RUN mkdir -p /app/code/phpmyadmin && \
    curl -L https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz | tar zxvf - -C /app/code/phpmyadmin --strip-components=1
COPY phpmyadmin-config.inc.php /app/code/phpmyadmin/config.inc.php

# ioncube. the extension dir comes from php -i | grep extension_dir
# extension has to appear first, otherwise will error with "The Loader must appear as the first entry in the php.ini file"
# ioncube does not seem to have support for PHP 8 yet (https://blog.ioncube.com/2022/08/12/ioncube-php-8-1-support-faq-were-almost-ready/)
RUN mkdir /tmp/ioncube && \
    curl http://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz | tar zxvf - -C /tmp/ioncube && \
    cp /tmp/ioncube/ioncube/ioncube_loader_lin_7.4.so /usr/lib/php/20190902/ && \
    cp /tmp/ioncube/ioncube/ioncube_loader_lin_8.1.so /usr/lib/php/20210902/ && \
    rm -rf /tmp/ioncube && \
    echo "zend_extension=/usr/lib/php/20190902/ioncube_loader_lin_7.4.so" > /etc/php/7.4/apache2/conf.d/00-ioncube.ini && \
    echo "zend_extension=/usr/lib/php/20190902/ioncube_loader_lin_7.4.so" > /etc/php/7.4/cli/conf.d/00-ioncube.ini && \
    echo "zend_extension=/usr/lib/php/20210902/ioncube_loader_lin_8.1.so" > /etc/php/8.1/apache2/conf.d/00-ioncube.ini && \
    echo "zend_extension=/usr/lib/php/20210902/ioncube_loader_lin_8.1.so" > /etc/php/8.1/cli/conf.d/00-ioncube.ini


# RUN mkdir whisper
# WORKDIR /app/code/whisper
# # install openai whisper
# RUN pip install -U openai-whisper

# # install ffmpeg
# RUN apt install ffmpeg

# # install rust
# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -y | sh

# RUN pip install setuptools-rust

# WORKDIR /app/code
# add code
WORKDIR /app/code
ADD start.sh /app/code/
COPY index.php credentials.template phpmyadmin_login.template /app/code/

# lock www-data but allow su - www-data to work
RUN passwd -l www-data && usermod --shell /bin/bash --home /app/data www-data

CMD [ "/app/code/start.sh" ]