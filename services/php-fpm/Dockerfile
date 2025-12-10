FROM php:8.3-fpm-alpine

# 安裝系統依賴
RUN apk add --no-cache \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libzip-dev \
    postgresql-dev \
    sqlite \
    git \
    bash \
    && docker-php-ext-configure gd --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    gd \
    zip \
    pdo \
    pdo_mysql \
    bcmath \
    ctype \
    fileinfo \
    json \
    tokenizer \
    xml \
    curl \
    && rm -rf /var/cache/apk/*

# 安裝 Redis 擴展
RUN pecl install redis && docker-php-ext-enable redis

# 設置 PHP 配置
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY php.ini-production $PHP_INI_DIR/conf.d/99-production.ini

# 安裝 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# 建立非 root 使用者
RUN addgroup -g 1000 appuser && adduser -D -u 1000 -G appuser appuser
USER appuser

CMD ["php-fpm"]