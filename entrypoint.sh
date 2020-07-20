#!/bin/bash
set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
NC="\033[0m"

# make sure mySQL-DB is ready:
while [[ -z $(mysql -hmysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"  <<< status)  ]]; do
    echo -e "${RED}waiting for mySQl-Server...${NC}"
    sleep 2
done
echo -e "${GREEN}->hello mySQl-Server :)${NC}"

# only if /Localconfiguration.php is not already present:
if  [ ! -f "./web/typo3conf/LocalConfiguration.php" ];
    then
        echo -e "${RED}==========================================${NC}"
        echo -e "${RED}==     PREPARING INITIAL TYPO3-SETUP    ==${NC}"
        echo -e "${RED}== existing database will be dropped !! ==${NC}"
        echo -e "${RED}==========================================${NC}"
        # reset existing database and composer.lock:
        mysql -hmysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"  <<< "DROP DATABASE IF EXISTS typo3; CREATE DATABASE typo3 DEFAULT CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci';"
        # run install-cmd
        composer install;
    else
        echo -e "${ORANGE}===================================${NC}"
        echo -e "${ORANGE}== TYPO3 is already installed  ==${NC}"
        echo -e "${ORANGE}===================================${NC}"
        composer update;
fi
chown -R www-data:www-data /var/www
# show PHP-Version:
php -v
echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}==      APACHE IS STARTING, CONTAINER IS READY       ==${NC}"
echo -e "${GREEN}=======================================================${NC}"

mkdir -p /run/php
service "php${PHP_VERSION}-fpm" restart
if [[ -z "$SERVICE_APACHE_OPTS" ]]; then SERVICE_APACHE_OPTS=""; fi
# Apache gets grumpy about PID files pre-existing
: "${APACHE_CONFDIR:=/etc/apache2}"
: "${APACHE_ENVVARS:=$APACHE_CONFDIR/envvars}"
if test -f "$APACHE_ENVVARS"; then
	. "$APACHE_ENVVARS"
fi

# Apache gets grumpy about PID files pre-existing
: "${APACHE_RUN_DIR:=/var/run/apache2}"
: "${APACHE_PID_FILE:=$APACHE_RUN_DIR/apache2.pid}"
rm -f "$APACHE_PID_FILE"

# create missing directories
# (especially APACHE_RUN_DIR, APACHE_LOCK_DIR, and APACHE_LOG_DIR)
for e in "${!APACHE_@}"; do
	if [[ "$e" == *_DIR ]] && [[ "${!e}" == /* ]]; then
		# handle "/var/lock" being a symlink to "/run/lock", but "/run/lock" not existing beforehand, so "/var/lock/something" fails to mkdir
		#   mkdir: cannot create directory '/var/lock': File exists
		dir="${!e}"
		while [[ "$dir" != "$(dirname "$dir")" ]]; do
			dir="$(dirname "$dir")"
			if [[ -d "$dir" ]]; then
				break
			fi
			absDir="$(readlink -f "$dir" 2>/dev/null || :)"
			if [[ -n "$absDir" ]]; then
				mkdir -p "$absDir"
			fi
		done

		mkdir -p "${!e}"
	fi
done

#apache2 -V
exec apache2 -DFOREGROUND -DAPACHE_LOCK_DIR $SERVICE_APACHE_OPTS
#exec "$@"