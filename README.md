[![](https://images.microbadger.com/badges/version/webstobe/php72.svg)](https://microbadger.com/images/webstobe/php72 "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/webstobe/php72.svg)](https://microbadger.com/images/webstobe/php72 "Get your own image badge on microbadger.com")
# php72 (with SSL)

overview
------------

- based on php:7.2-apache
- composer from official image
- additional tools:
  - wget
  - nano
  - vim
  - git
  - unzip / zip
  - rsync
  - graphicsmagick
  - mysql-client
  - ssh
  - jpegoptim
  - optipng
  - gifsicle
  - poppler-utils (pdftotext / pdftohtml ...)

##### 2019-08-30 
- add most used locales to the image
- replace mysql-client with mariadb-client (because of update to php-image)

##### 2019-01-25 
- drop auto-import of DB to avoid interference with composer-scripts and manual migrations