# ------------------------------------------------------------------------------
# Estágio 1: Builder
# ------------------------------------------------------------------------------
FROM php:8.2-fpm-alpine AS builder

# Dependências de build
RUN apk add --no-cache \
    build-base \
    git \
    curl \
    libzip-dev \
    oniguruma-dev \
    libxml2-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    zlib-dev \
    openssl

# Extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" \
    gd \
    pdo_mysql \
    zip \
    bcmath \
    exif \
    pcntl \
    soap \
    calendar \
    opcache

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copia arquivos do composer primeiro (cache de camadas)
COPY composer.json composer.lock ./

# Instala dependências
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1
RUN composer install --no-interaction --no-dev --prefer-dist --optimize-autoloader --no-scripts

# Copia o resto da aplicação
COPY . .

# Gera autoload otimizado
RUN composer dump-autoload -o

# ------------------------------------------------------------------------------
# Estágio 2: Runtime
# ------------------------------------------------------------------------------
FROM php:8.2-fpm-alpine

# Dependências runtime
RUN apk add --no-cache \
    nginx \
    supervisor \
    libzip \
    oniguruma \
    libxml2 \
    freetype \
    libjpeg-turbo \
    libpng \
    bash \
    tzdata \
    openssl \
    netcat-openbsd

WORKDIR /var/www/html

# Copia extensões PHP do builder
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Copia aplicação com vendor
COPY --from=builder /var/www/html /var/www/html

# Configuração do PHP
RUN echo "memory_limit=256M" > /usr/local/etc/php/conf.d/memory.ini && \
    echo "upload_max_filesize=32M" > /usr/local/etc/php/conf.d/upload.ini && \
    echo "post_max_size=32M" >> /usr/local/etc/php/conf.d/upload.ini && \
    echo "max_execution_time=300" > /usr/local/etc/php/conf.d/execution.ini

# Copia configurações
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Permissões
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chown -R www-data:www-data /var/www/html

# NÃO adicionar "daemon off;" aqui - já está no nginx.conf

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]