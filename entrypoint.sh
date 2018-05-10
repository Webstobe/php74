#!/bin/bash

# change directory:
cd /var/www

# only if /typo3-folder is not already present:
if  [ ! -d "/var/www/web/typo3" ];then
    echo -e "==================================="
    echo -e "== PREPARING INITIAL TYPO3-SETUP =="
    echo -e "==================================="
    # run composer update
    composer update

    # run TYPO3-setup:
    typo3cms install:setup --no-interaction --force --skip-extension-setup --database-user-name=dev --database-user-password=dev --database-host-name=mysql --database-port=3306 --database-name=typo3 --admin-user-name='admin' --admin-password='password' --site-name='Docker' --database-create=0 --use-existing-database  --site-setup-type=no

    # restore DB:
    typo3cms database:import < /var/www/ingredients/mysql/initialdump.sql

    # generate packagestates including core-extensions specified in composer.json:
    typo3cms install:generatepackagestates

    # typo3console extension:setupactive
    typo3cms extension:setupactive

    # check the DB-scheme
    typo3cms database:updateschema

    # fix folder permissions
    typo3cms install:fixfolderstructure

    # install DE-language
    typo3cms language:update --locales-to-update de

    # finally cache:flush
    typo3cms cache:flush

fi

if  [ ! -d "/var/www/web/fileadmin/user_upload/test_files" ];then
    echo -e "============================"
    echo -e "== initializing fileadmin =="
    echo -e "============================"
    cp -r /var/www/ingredients/fileadmin/user_upload/test_files /var/www/web/fileadmin/user_upload/test_files/
    cp -r /var/www/ingredients/fileadmin/user_upload/logos /var/www/web/fileadmin/user_upload/logos/
fi

# chown /var/www:
chown -R www-data:www-data /var/www

echo -e "==================================="
echo -e "==      CONTAINER IS READY       =="
echo -e "==================================="

exec "$@"
#/bin/bash