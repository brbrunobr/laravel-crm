#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# docker-entrypoint.sh - VERSÃO CORRIGIDA
# ------------------------------------------------------------------------------
# Corrige problema de APP_KEY e encoding
# ------------------------------------------------------------------------------

set -euo pipefail

# Sempre trabalhar no diretório do app
cd /var/www/html

echo "==> Iniciando configuração do Laravel/Krayin..."

# 1) Garante que o .env exista
if [ ! -f .env ]; then
  echo "==> Criando .env a partir do .env.example..."
  cp -f .env.example .env 2>/dev/null || touch .env
fi

# 2) Verifica se existe APP_KEY no .env
CURRENT_KEY=$(grep -E '^APP_KEY=' .env | cut -d= -f2- | tr -d ' ' || echo "")

# 3) Se não houver APP_KEY válida, gera uma nova
if [ -z "$CURRENT_KEY" ] || [ "$CURRENT_KEY" = "" ] || [ "$CURRENT_KEY" = "null" ]; then
  echo "==> Gerando nova APP_KEY..."
  # Usa o artisan para gerar a chave (método mais seguro)
  php artisan key:generate --force || {
    # Fallback manual se o artisan falhar
    echo "==> Gerando APP_KEY manualmente..."
    NEW_KEY="base64:$(openssl rand -base64 32)"
    if grep -q '^APP_KEY=' .env; then
      sed -i "s|^APP_KEY=.*|APP_KEY=${NEW_KEY}|" .env
    else
      echo "APP_KEY=${NEW_KEY}" >> .env
    fi
  }
else
  echo "==> APP_KEY já existe: ${CURRENT_KEY:0:20}..."
fi

# 4) Se APP_KEY vier do ambiente, sobrescreve
if [ -n "${APP_KEY:-}" ]; then
  echo "==> Usando APP_KEY do ambiente..."
  # Remove prefixo duplicado se houver
  APP_KEY="${APP_KEY/base64:base64:/base64:}"
  
  if [[ "$APP_KEY" == base64:* ]]; then
    if grep -q '^APP_KEY=' .env; then
      sed -i "s|^APP_KEY=.*|APP_KEY=${APP_KEY}|" .env
    else
      echo "APP_KEY=${APP_KEY}" >> .env
    fi
  else
    echo "AVISO: APP_KEY do ambiente não está no formato correto"
  fi
fi

# 5) Configura variáveis adicionais importantes
echo "==> Configurando variáveis do ambiente..."

# APP_URL do ambiente
if [ -n "${APP_URL:-}" ]; then
  if grep -q '^APP_URL=' .env; then
    sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" .env
  else
    echo "APP_URL=${APP_URL}" >> .env
  fi
fi

# DB_HOST do ambiente
if [ -n "${DB_HOST:-}" ]; then
  if grep -q '^DB_HOST=' .env; then
    sed -i "s|^DB_HOST=.*|DB_HOST=${DB_HOST}|" .env
  else
    echo "DB_HOST=${DB_HOST}" >> .env
  fi
fi

# Outras variáveis de DB
for var in DB_DATABASE DB_USERNAME DB_PASSWORD DB_PORT; do
  value=$(eval echo "\${$var:-}")
  if [ -n "$value" ]; then
    if grep -q "^$var=" .env; then
      sed -i "s|^$var=.*|$var=$value|" .env
    else
      echo "$var=$value" >> .env
    fi
  fi
done

# 6) Ajusta permissões ANTES de limpar caches
echo "==> Ajustando permissões..."
chown -R www-data:www-data /var/www/html
chmod -R 755 storage bootstrap/cache
chmod -R 775 storage/logs storage/app storage/framework

# 7) IMPORTANTE: Limpa TODOS os caches antes de recriar
echo "==> Limpando caches antigos..."
rm -rf bootstrap/cache/*.php
rm -rf storage/framework/cache/data/*
rm -rf storage/framework/sessions/*
rm -rf storage/framework/views/*.php

# Limpa via artisan também
php artisan cache:clear || true
php artisan config:clear || true
php artisan route:clear || true
php artisan view:clear || true

# 8) Recria os caches com a nova configuração
echo "==> Recriando caches..."
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# 9) Cria link do storage
echo "==> Criando link do storage..."
php artisan storage:link --force || true

# 10) Aguarda o banco de dados (se configurado)
if [ -n "${DB_HOST:-}" ]; then
  echo "==> Aguardando banco de dados..."
  timeout=30
  while ! nc -z "${DB_HOST}" "${DB_PORT:-3306}" 2>/dev/null; do
    timeout=$((timeout - 1))
    if [ $timeout -le 0 ]; then
      echo "AVISO: Timeout aguardando banco de dados"
      break
    fi
    echo "Aguardando DB... ($timeout)"
    sleep 1
  done
fi

# 11) Roda migrações se o banco estiver disponível
if [ -n "${DB_HOST:-}" ] && nc -z "${DB_HOST}" "${DB_PORT:-3306}" 2>/dev/null; then
  echo "==> Executando migrações..."
  php artisan migrate --force || echo "AVISO: Migrações falharam ou já executadas"
fi

# 12) Marca como instalado (para Krayin)
touch storage/app/installed || true

# 13) Verifica se a APP_KEY foi configurada corretamente
echo "==> Verificando configuração final..."
php artisan tinker --execute="echo 'APP_KEY configurada: ' . (config('app.key') ? 'OK' : 'ERRO');" || true

echo "==> Configuração concluída! Iniciando supervisord..."

# Executa o comando principal
exec "$@"