#!/bin/bash

set -eu

mkdir -p /app/data/public /run/apache2 /run/cron /run/app/sessions

# check if any index file exists
for f in /app/data/public/index.*; do
    [ -e "$f" ] && echo "Do not override existing index file" || cp /app/code/index.php /app/data/public/index.php
    break
done

if [ ! -f "/app/data/php.ini" ]; then
    cp /etc/php/7.2/apache2/php.ini.orig /app/data/php.ini
else
    crudini --set /app/data/php.ini Session session.gc_probability 1
    crudini --set /app/data/php.ini Session session.gc_divisor 100
fi

## Remove old sftpd folders
## TODO remove this line in later versions
rm -rf /app/data/sftpd

## Generate apache config
sed -e "s@AuthLDAPURL .*@AuthLDAPURL ${LDAP_URL}/${LDAP_USERS_BASE_DN}?username??(objectclass=user)@" \
    -e "s@AuthLDAPBindDN .*@AuthLDAPBindDN ${LDAP_BIND_DN}@" \
    -e "s@AuthLDAPBindPassword .*@AuthLDAPBindPassword ${LDAP_BIND_PASSWORD}@" \
    /app/code/lamp.conf > /run/apache2/lamp.conf

## hook for custom start script in /app/data/run.sh
if [ -f "/app/data/run.sh" ]; then
    /bin/bash /app/data/run.sh
fi

[[ ! -f /app/data/crontab ]] && cp /app/code/crontab.template /app/data/crontab

## configure in-container Crontab
# http://www.gsp.com/cgi-bin/man.cgi?section=5&topic=crontab
if ! (env; cat /app/data/crontab; echo -e '\nMAILTO=""') | crontab -u www-data -; then
    echo "Error importing crontab. Continuing anyway"
else
    echo "Imported crontab"
fi

echo "=> Creating credentials.txt"
sed -e "s,MYSQL_HOST,${MYSQL_HOST}," \
    -e "s,MYSQL_PORT,${MYSQL_PORT}," \
    -e "s,MYSQL_USERNAME,${MYSQL_USERNAME}," \
    -e "s,MYSQL_PASSWORD,${MYSQL_PASSWORD}," \
    -e "s,MYSQL_DATABASE,${MYSQL_DATABASE}," \
    -e "s,MYSQL_URL,${MYSQL_URL}," \
    -e "s,MAIL_SMTP_SERVER,${MAIL_SMTP_SERVER}," \
    -e "s,MAIL_SMTP_PORT,${MAIL_SMTP_PORT}," \
    -e "s,MAIL_SMTPS_PORT,${MAIL_SMTPS_PORT}," \
    -e "s,MAIL_SMTP_USERNAME,${MAIL_SMTP_USERNAME}," \
    -e "s,MAIL_SMTP_PASSWORD,${MAIL_SMTP_PASSWORD}," \
    -e "s,MAIL_FROM,${MAIL_FROM}," \
    -e "s,MAIL_DOMAIN,${MAIL_DOMAIN}," \
    -e "s,REDIS_HOST,${REDIS_HOST}," \
    -e "s,REDIS_PORT,${REDIS_PORT}," \
    -e "s,REDIS_PASSWORD,${REDIS_PASSWORD}," \
    -e "s,REDIS_URL,${REDIS_URL}," \
    -e "s,LDAP_SERVER,${LDAP_SERVER}," \
    -e "s,LDAP_PORT,${LDAP_PORT}," \
    -e "s|LDAP_USERS_BASE_DN|${LDAP_USERS_BASE_DN}|" \
    -e "s|LDAP_GROUPS_BASE_DN|${LDAP_GROUPS_BASE_DN}|" \
    -e "s|LDAP_BIND_DN|${LDAP_BIND_DN}|" \
    -e "s,LDAP_BIND_PASSWORD,${LDAP_BIND_PASSWORD}," \
    -e "s,LDAP_URL,${LDAP_URL}," \
    /app/code/credentials.template > /app/data/credentials.txt

chown -R www-data:www-data /app/data /run/apache2 /run/app

echo "Starting supervisord"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i Lamp
