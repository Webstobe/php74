#!/bin/bash

# change directory:
cd /var/www

# only if /Localconfiguration.php is not already present:
if  [ ! -f "./web/typo3conf/LocalConfiguration.php" ];
    then
        echo -e "==================================="
        echo -e "== PREPARING INITIAL TYPO3-SETUP =="
        echo -e "==================================="
        composer install;
        # restore DB:
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

exec "$@"
#/bin/bash