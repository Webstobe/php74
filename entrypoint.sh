#!/bin/bash

# change directory:
cd /var/www

# only if /Localconfiguration.php is not already present:
if  [ ! -f "./web/typo3conf/LocalConfiguration.php" ];
    then
        echo -e "==================================="
        echo -e "== PREPARING INITIAL TYPO3-SETUP =="
        echo -e "==================================="
        # reset existing database and composer.lock:
        mysql -hmysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"  <<< "DROP DATABASE IF EXISTS typo3; CREATE DATABASE typo3;"
        rm -f composer.lock
        # first refresh the composer.lock file to have a proper install:
        composer update nothing --no-scripts
        #now run install-cmd
        composer install;
        # remove admin-user and restore default-DB:
        mysql -hmysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD"  <<< "DELETE FROM typo3.be_users WHERE username='admin';"
        typo3cms database:import < /var/www/ingredients/mysql/initialdump.sql
    else
        echo -e "==================================="
        echo -e "== TYPO3 is already installed  =="
        echo -e "==================================="
        composer update;
fi

# chown /var/www:
chown -R www-data:www-data /var/www

echo -e "==================================="
echo -e "==      CONTAINER IS READY       =="
echo -e "==================================="

# show PHP-Version:
php -v

exec "$@"
#/bin/bash