# Estágio 1: Builder - Instala todas as dependências de build e compila tudo
FROM php:8.2-fpm-alpine AS builder

# Instala dependências do sistema necessárias para compilação
RUN apk add --no-cache \
    build-base \
    git \
    curl \
    supervisor \
    libzip-dev \
    zip \
    oniguruma-dev \
    libxml2-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    zlib-dev

# Instala extensões do PHP necessárias para o Laravel/Krayin
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    pdo_mysql \
    zip \
    bcmath \
    exif \
    pcntl \
    soap \
    calendar

# Instala o Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Define o diretório de trabalho
WORKDIR /var/www/html

# Copia os arquivos de dependência e instala os pacotes do Composer
COPY composer.json composer.lock ./
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Copia o resto do código da aplicação
COPY . .


# Estágio 2: Produção - A imagem final, limpa e otimizada
FROM php:8.2-fpm-alpine

# Instala apenas as dependências de sistema necessárias para RODAR (não para compilar)
RUN apk add --no-cache \
    nginx \
    supervisor \
    libzip \
    oniguruma \
    libxml2 \
    freetype \
    libjpeg-turbo \
    libpng

# Define o diretório de trabalho
WORKDIR /var/www/html

# Copia os arquivos de configuração das extensões PHP já compiladas
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copia os arquivos das extensões PHP já compiladas
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/

# Copia a aplicação inteira (incluindo a pasta /vendor) do estágio 'builder'
COPY --from=builder /var/www/html .

# Copia os arquivos de configuração do Nginx e Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Garante que o Nginx não vai rodar como daemon (necessário para o Supervisor)
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Ajusta as permissões das pastas do Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Expõe a porta 80 para o tráfego web
EXPOSE 80

# Comando para iniciar o Supervisor, que por sua vez inicia o Nginx e o PHP-FPM
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]