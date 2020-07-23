FROM composer AS composer
FROM debian:buster-slim

#03 set ENV variables
ENV PHP_VERSION 7.4
ENV DEBIAN_FRONTEND=noninteractive \
    DATE_TIMEZONE="Europe/Zurich" \
    SHELL=/bin/bash \
    APACHE_DOCUMENT_ROOT="/var/www/web" \
    COMPOSER_HOME="$HOME/.config/composer" \
    PATH="/var/www/vendor/bin:$PATH"

# 02
MAINTAINER Nando Bosshart <nando@webstobe.ch>

RUN apt-get update -q && apt-get -y install wget apt-transport-https lsb-release ca-certificates && \
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

RUN apt-get update -q && \
    apt-get -yqq install \
        locales \
        sudo \
        wget \
        nano \
        vim \
        git \
        unzip \
        zip \
        ssh \
        curl \
        libxml2-dev libfreetype6-dev \
        libjpeg62-turbo-dev \
        libjpeg-turbo-progs \
        libpng-dev \
        libwebp-dev \
        libldap2-dev \
        rsync \
        libbz2-dev \
        libxslt-dev \
        libzip-dev \
        graphicsmagick \
        ghostscript \
        jpegoptim \
        optipng \
        gifsicle \
        poppler-utils \
        ffmpeg \
        mariadb-client \
        apache2 \
        php${PHP_VERSION}-apcu \
        php${PHP_VERSION}-bz2 \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-exif \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-xdebug \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-xsl \
        webp libimage-exiftool-perl html2text xfonts-75dpi  \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/*


RUN wget https://github.com/imagemin/zopflipng-bin/raw/master/vendor/linux/zopflipng -O /usr/local/bin/zopflipng && \
    wget https://github.com/imagemin/pngcrush-bin/raw/master/vendor/linux/pngcrush -O /usr/local/bin/pngcrush && \
    wget https://github.com/imagemin/jpegoptim-bin/raw/master/vendor/linux/jpegoptim -O /usr/local/bin/jpegoptim && \
    wget https://github.com/imagemin/pngout-bin/raw/master/vendor/linux/x64/pngout -O /usr/local/bin/pngout && \
    wget https://github.com/imagemin/advpng-bin/raw/master/vendor/linux/advpng -O /usr/local/bin/advpng && \
    wget https://github.com/imagemin/mozjpeg-bin/raw/master/vendor/linux/cjpeg -O /usr/local/bin/cjpeg && \
    chmod +x /usr/local/bin/*


# 04 set desired timezone
RUN echo $DATE_TIMEZONE >/etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# install locales
RUN sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# de_CH.UTF-8 UTF-8/de_CH.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# it_IT.UTF-8 UTF-8/it_IT.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# it_CH.UTF-8 UTF-8/it_CH.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# fr_CH.UTF-8 UTF-8/fr_CH.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# configure Apache
RUN a2enmod actions alias proxy_fcgi proxy proxy_http rewrite setenvif expires headers ssl && \
    a2enconf "php${PHP_VERSION}-fpm"

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e "s?AllowOverride None?AllowOverride All?g" /etc/apache2/apache2.conf && \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# install composer globally - the ENV variables are already set:
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /usr/src/*
# Configure user
RUN echo "www-data:www-data" | chpasswd && adduser www-data sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN mkdir -p /home/www-data/.ssh && \
    mkdir -p /home/www-data/.composer && \
    chmod -R 600 /home/www-data/.ssh
RUN usermod -d /home/www-data www-data  && \
    chown -R www-data:www-data /var/www /home/www-data

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www
USER www-data
ENTRYPOINT []
CMD ["sudo", "-E", "bash", "/usr/local/bin/entrypoint.sh"]