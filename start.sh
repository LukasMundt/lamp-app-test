#!/bin/bash

set -eu

mkdir -p /app/data/public /run/apache2 /run/cron /run/app/sessions

# check if any index file exists
for f in /app/data/public/index.*; do
    [ -e "$f" ] && echo "Do not override existing index file" || cp /app/code/index.php /app/data/public/index.php
    break
done

if [[ ! -f "/app/data/php.ini" ]]; then
    echo "==> Generating php.ini"
    cp /etc/php/7.2/apache2/php.ini.orig /app/data/php.ini
else
    crudini --set /app/data/php.ini Session session.gc_probability 1
    crudini --set /app/data/php.ini Session session.gc_divisor 100
fi

## hook for custom start script in /app/data/run.sh
echo "==> Running custom startup script"
[[ -f "/app/data/run.sh" ]] && /bin/bash /app/data/run.sh

[[ ! -f /app/data/crontab ]] && cp /app/code/crontab.template /app/data/crontab

## configure in-container Crontab
# http://www.gsp.com/cgi-bin/man.cgi?section=5&topic=crontab
if ! (env; cat /app/data/crontab; echo -e '\nMAILTO=""') | crontab -u www-data -; then
    echo "==> Error importing crontab. Continuing anyway"
else
    echo "==> Imported crontab"
fi

# phpMyAdmin auth file
if [[ ! -f /app/data/.phpmyadminauth ]]; then
    echo "==> Generating phpMyAdmin authentication file"
    PASSWORD=`pwgen -1 16`
    htpasswd -cb /app/data/.phpmyadminauth admin "${PASSWORD}"
    sed -e "s,PASSWORD,${PASSWORD}," /app/code/phpmyadmin_login.template > /app/data/phpmyadmin_login.txt
fi

echo "==> Creating credentials.txt"
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
    /app/code/credentials.template > /app/data/credentials.txt

chown -R www-data:www-data /app/data /run/apache2 /run/app

echo "==> Starting Lamp stack"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i Lamp
