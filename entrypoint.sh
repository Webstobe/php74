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
exec apache2-foreground
#exec "$@"