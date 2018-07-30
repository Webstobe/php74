#!/bin/bash
RED="\033[0;31m"
GREEN="\033[0;32m"
ORANGE="\033[0;33m"
NC="\033[0m"

# change directory:
cd /var/www

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
        echo -e "${ORANGE}===================================${NC}"
        echo -e "${ORANGE}== TYPO3 is already installed  ==${NC}"
        echo -e "${ORANGE}===================================${NC}"
        composer update;
fi

# chown /var/www:
chown -R www-data:www-data /var/www

echo -e "${GREEN}===================================${NC}"
echo -e "${GREEN}==      CONTAINER IS READY       ==${NC}"
echo -e "${GREEN}===================================${NC}"

# show PHP-Version:
php -v

exec "$@"
#/bin/bash