#!/bin/bash

set -eu

mkdir -p /app/data/public /run/apache2 /run/cron /run/app/sessions

# generate files if neither index.* or .htaccess
if [[ -z "$(ls -A /app/data/public)" ]]; then
    echo "==> Generate files on first run" # possibly not first run if user deleted index.*
    cp /app/code/index.php /app/data/public/index.php
    echo -e "#!/bin/bash\n\n# Place custom startup commands here" > /app/data/run.sh
    touch /app/data/public/.htaccess
else
    echo "==> Do not override existing index file"
fi

if [[ ! -f "/app/data/php.ini" ]]; then
    echo "==> Generating php.ini"
    cp /etc/php/7.4/apache2/php.ini.orig /app/data/php.ini
    crudini --set /app/data/php.ini Session session.gc_probability 1
    crudini --set /app/data/php.ini Session session.gc_divisor 100
fi

# source it so that env vars are persisted
echo "==> Source custom startup script"
[[ -f /app/data/run.sh ]] && source /app/data/run.sh

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
sed -e "s,MYSQL_HOST,${CLOUDRON_MYSQL_HOST}," \
    -e "s,MYSQL_PORT,${CLOUDRON_MYSQL_PORT}," \
    -e "s,MYSQL_USERNAME,${CLOUDRON_MYSQL_USERNAME}," \
    -e "s,MYSQL_PASSWORD,${CLOUDRON_MYSQL_PASSWORD}," \
    -e "s,MYSQL_DATABASE,${CLOUDRON_MYSQL_DATABASE}," \
    -e "s,MYSQL_URL,${CLOUDRON_MYSQL_URL}," \
    -e "s,MAIL_SMTP_SERVER,${CLOUDRON_MAIL_SMTP_SERVER}," \
    -e "s,MAIL_SMTP_PORT,${CLOUDRON_MAIL_SMTP_PORT}," \
    -e "s,MAIL_SMTPS_PORT,${CLOUDRON_MAIL_SMTPS_PORT}," \
    -e "s,MAIL_SMTP_USERNAME,${CLOUDRON_MAIL_SMTP_USERNAME}," \
    -e "s,MAIL_SMTP_PASSWORD,${CLOUDRON_MAIL_SMTP_PASSWORD}," \
    -e "s,MAIL_FROM,${CLOUDRON_MAIL_FROM}," \
    -e "s,MAIL_DOMAIN,${CLOUDRON_MAIL_DOMAIN}," \
    -e "s,REDIS_HOST,${CLOUDRON_REDIS_HOST}," \
    -e "s,REDIS_PORT,${CLOUDRON_REDIS_PORT}," \
    -e "s,REDIS_PASSWORD,${CLOUDRON_REDIS_PASSWORD}," \
    -e "s,REDIS_URL,${CLOUDRON_REDIS_URL}," \
    /app/code/credentials.template > /app/data/credentials.txt

chown -R www-data:www-data /app/data /run/apache2 /run/app /tmp

echo "==> Starting Lamp stack"
exec /usr/bin/supervisord --configuration /etc/supervisor/supervisord.conf --nodaemon -i Lamp
