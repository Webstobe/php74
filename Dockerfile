FROM composer AS composer
FROM php:7.4-apache
# 02
MAINTAINER Nando Bosshart <nando@webstobe.ch>
#03 set ENV variables
ENV APACHE_DOCUMENT_ROOT="/var/www/web" COMPOSER_ALLOW_SUPERUSER=1 PATH="/var/www/vendor/bin:$PATH"

# 04 set desired timezone
RUN echo Europe/Zurich >/etc/timezone && \
dpkg-reconfigure -f noninteractive tzdata

# 05
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 06 install some additions on top of our image
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        nano \
        vim \
        git \
        unzip \
        zip \
        ssh \
        libxml2-dev libfreetype6-dev \
        libjpeg62-turbo-dev \
        libjpeg-turbo-progs \
        libpng-dev \
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
        webp libimage-exiftool-perl \
        html2text \
        mariadb-client \
        locales && \
# configure extensions
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install -j$(nproc) bz2 dom exif gd intl mysqli pdo_mysql soap zip opcache intl ldap xsl && \
    pecl install xdebug && \
    pecl install apcu && \
    pecl install -o -f redis && \
    rm -rf /tmp/pear && \
    docker-php-ext-enable redis && \
# install locales
    sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# de_CH.UTF-8 UTF-8/de_CH.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# it_IT.UTF-8 UTF-8/it_IT.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# it_CH.UTF-8 UTF-8/it_CH.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# fr_CH.UTF-8 UTF-8/fr_CH.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /usr/src/*
# 07 configure Apache
RUN a2enmod rewrite ssl proxy proxy_http alias expires headers
# 08 install composer globally - the ENV variables are already set:
COPY --from=composer /usr/bin/composer /usr/bin/composer
# 09 Configure volumes
# these volumes stay persistent:
VOLUME /var/www
RUN echo "www-data:www-data" | chpasswd && adduser www-data sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN usermod -d /home/www-data www-data
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
WORKDIR /var/www
USER root:www-data
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sudo", "-E", "bash", "/usr/local/bin/entrypoint.sh"]