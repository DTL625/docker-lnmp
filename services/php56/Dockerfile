FROM php:5.6.32-fpm
MAINTAINER LDT "watshing625@gmail.com"

# 設定timezone
ENV TZ=Asia/Taipei
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#替換鏡像源
ENV SOURCELIST_FROM=aliyun
COPY ./pkg/${SOURCELIST_FROM}_sourcelist /home/sources.list
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak && mv /home/sources.list /etc/apt/

# 更新安裝依賴包和PHP核心拓展
RUN apt-get update && apt-get install -y \
        git \
        vim \
        curl \
        wget \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libssl-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
        && docker-php-ext-install zip \
        && docker-php-ext-install pdo_mysql \
        && docker-php-ext-install opcache \
        && docker-php-ext-install mysqli \
        && docker-php-ext-install mysql \
        && rm -r /var/lib/apt/lists/*

# 將預先下載好的拓展包從宿主機拷貝進去
COPY ./pkg/redis.tgz /home/redis.tgz
COPY ./pkg/libmemcached.tar.gz /home/libmemcached.tar.gz
COPY ./pkg/memcached-2.2.0.tgz /home/memcached-2.2.0.tgz

# 安裝 PECL 拓展，這裡我們安裝的是Redis
RUN pecl install /home/redis.tgz && echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

# 安裝libmemcached
RUN tar zxvf /home/libmemcached.tar.gz \
    && cd libmemcached-1.0.18 \
    && ./configure --prefix=/usr/local/libmemcached --with-memcached \
    && make && make install

# 安裝memcached
RUN tar zxvf /home/memcached-2.2.0.tgz \
    && cd memcached-2.2.0 \
    && phpize \
    && ./configure -enable-memcached -with-php-config=/usr/local/bin/php-config -with-zlib-dir -with-libmemcached-dir=/usr/local/libmemcached -prefix=/usr/local/phpmemcached -disable-memcached-sasl \
    && make && make install \
    && echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini



# 安裝opencc
COPY ./pkg/opencc.tar /home/opencc.tar
RUN apt-get update && apt-get install -y \
    doxygen \
    cmake \
    python

RUN tar zxvf /home/opencc.tar \
        && cd OpenCC \
        && make && make install

# 安裝opencc4php擴展
COPY ./pkg/opencc4php.tar /home/opencc4php.tar
RUN tar zxvf /home/opencc4php.tar \
        && cd opencc4php \
        && phpize \
        && ./configure \
        && make && make install \
        && echo "extension=opencc.so" > /usr/local/etc/php/conf.d/opencc.ini

# 安裝 Composer
ENV COMPOSER_HOME /root/composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV PATH $COMPOSER_HOME/vendor/bin:$PATH

# 安裝memcache
RUN pecl install memcache && \
    echo "extension=memcache.so" > /usr/local/etc/php/conf.d/memcache.ini


# 刪除擴展包
RUN rm -f /home/redis.tgz
RUN rm -f /home/libmemcached.tar.gz
RUN rm -f /home/memcached.tgz
RUN rm -f /home/opencc4php
RUN rm -f /home/OpenCC

WORKDIR /data

# 寫權限
RUN usermod -u 1000 www-data


# 安裝額外擴展
RUN apt-get update && apt-get install -y \
        libmcrypt-dev \
        libxml2-dev \
        && docker-php-ext-install mcrypt bcmath mbstring opcache soap

# 安裝xdebug
RUN pecl install xdebug-2.3.3 && \
    docker-php-ext-enable xdebug
COPY ./pkg/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# 安裝gnupg擴展
RUN apt-get install -y libgpgme11-dev &&  pecl install gnupg && echo "extension=gnupg.so" > /usr/local/etc/php/conf.d/gnupg.ini



# 安裝 Swoole
#RUN cd /home \
#    && git clone https://gitee.com/swoole/swoole.git \
#    && cd swoole \
#    && phpize \
#    && ./configure --enable-openssl -with-php-config=/usr/local/bin/php-config \
#    && make \
#    && make install \
#    && echo "extension=swoole.so" > /usr/local/etc/php/conf.d/swoole.ini