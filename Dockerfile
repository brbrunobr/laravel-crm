# ------------------------------------------------------------------------------
# Estágio 1: Builder  (compila extensões e instala dependências do Composer)
# ------------------------------------------------------------------------------
FROM php:8.2-fpm-alpine AS builder

# 1) Dependências de build (apenas para compilar extensões e rodar composer)
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
    zlib-dev

# 2) Compila extensões do PHP necessárias (Laravel/Krayin)
#    - gd (com jpeg/freetype), pdo_mysql, zip, bcmath, exif, pcntl, soap, calendar
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" \
    gd \
    pdo_mysql \
    zip \
    bcmath \
    exif \
    pcntl \
    soap \
    calendar

# 3) Composer (copiado da imagem oficial)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4) Diretório de trabalho
WORKDIR /var/www/html

# 5) Melhora o cache do Composer: copia apenas manifestos e instala **sem scripts**
#    - Evita rodar @php artisan package:discover antes do código estar presente
COPY composer.json composer.lock ./
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_MEMORY_LIMIT=-1
RUN composer install --no-interaction --no-dev --prefer-dist --optimize-autoloader --no-scripts

# 6) Agora copia o restante do app (inclui "artisan" e pastas do projeto)
COPY . .

# 7) Gera autoload otimizado (ainda sem disparar scripts do Composer)
RUN composer dump-autoload -o

# ------------------------------------------------------------------------------
# Estágio 2: Runtime (imagem final enxuta com Nginx + PHP-FPM + supervisord)
# ------------------------------------------------------------------------------
FROM php:8.2-fpm-alpine

# 1) Dependências necessárias em runtime (sem toolchain de build)
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
    tzdata

# 2) Diretório de trabalho
WORKDIR /var/www/html

# 3) Copia extensões e INIs do PHP do "builder"
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# 4) Copia o código da aplicação já com vendor (do "builder")
COPY --from=builder /var/www/html /var/www/html

# 5) Copia configs do Nginx e do Supervisor (você já tem esses arquivos)
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf

# 6) Copia o entrypoint (script acima) e dá permissão de execução
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 7) Garante que o Nginx não rode como daemon (o supervisord gerencia)
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# 8) Exponha a porta HTTP para o proxy (Coolify/Traefik)
EXPOSE 80

# 9) Define o entrypoint:
#    - Ele vai normalizar APP_KEY, caches, permissões etc
ENTRYPOINT ["docker-entrypoint.sh"]

# 10) Comando padrão:
#     - O supervisor gerencia Nginx e PHP-FPM; seu "supervisord.conf" deve ter os programas
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
