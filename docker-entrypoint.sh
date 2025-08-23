#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# docker-entrypoint.sh
# ------------------------------------------------------------------------------
# Objetivo:
# - Garantir que o .env exista
# - Normalizar a APP_KEY quando vier do ambiente com "base64:base64:" (bug comum)
# - Gerar APP_KEY se estiver ausente/inválida
# - Ajustar permissões (storage e cache)
# - Criar storage:link
# - Limpar e recachear configurações/rotas/views
# - (Opcional) Rodar migrações/seed quando o banco estiver acessível
# - Por fim, executar o "processo principal" do container (supervisord)
# ------------------------------------------------------------------------------

set -euo pipefail

# Sempre trabalhar no diretório do app
cd /var/www/html

# Aguarda um pequeno tempo para serviços subirem em ambientes mais lentos (opcional)
# Dica: prefira healthchecks de DB em vez de um sleep fixo.
# sleep 5

# 1) Garante que o .env exista
#    - Se o arquivo .env não existir, copia do exemplo (não falha se não houver)
if [ ! -f .env ]; then
  cp -f .env.example .env || true
fi

# 2) Lê a APP_KEY que está no .env (se houver)
#    - Usamos "cut -d= -f2-" para manter tudo após o "=" (inclui "base64:...")
ENV_APP_KEY="$(grep -E '^APP_KEY=' .env | head -n1 | cut -d= -f2- || true)"

# 3) Normaliza uma APP_KEY vinda do ambiente (Coolify / Docker)
#    - Se vier como "base64:base64:..." corrigimos para "base64:..."
#    - Se vier sem "base64:", consideramos inválida e ignoramos
RUNTIME_APP_KEY="${APP_KEY:-}"
if [ -n "${RUNTIME_APP_KEY}" ]; then
  # Corrige prefixo duplicado "base64:base64:"
  RUNTIME_APP_KEY="${RUNTIME_APP_KEY/base64:base64:/base64:}"
  # Aceita apenas se começar com "base64:"
  if [[ "${RUNTIME_APP_KEY}" != base64:* ]]; then
    echo "WARN: APP_KEY do ambiente não está no formato base64:..., será ignorada."
    RUNTIME_APP_KEY=""
  fi
fi

# 4) Decide a APP_KEY a ser usada:
#    - Preferimos a do ambiente (se válida) > a do .env (se válida) > geramos nova
USE_KEY=""
if [ -n "${RUNTIME_APP_KEY}" ]; then
  USE_KEY="${RUNTIME_APP_KEY}"
elif [[ "${ENV_APP_KEY}" == base64:* ]]; then
  USE_KEY="${ENV_APP_KEY}"
else
  # Gera nova chave (32 bytes aleatórios) no formato "base64:..."
  NEW_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
  USE_KEY="${NEW_KEY}"
fi

# 5) Escreve/garante APP_KEY no .env
#    - Se já houver APP_KEY, substitui
#    - Se não houver, adiciona ao final
if grep -q '^APP_KEY=' .env; then
  sed -i "s#^APP_KEY=.*#APP_KEY=${USE_KEY}#g" .env
else
  echo "APP_KEY=${USE_KEY}" >> .env
fi

# 6) (Opcional) Ajustes que ajudam em produção/proxy
#    - SESSION_SECURE_COOKIE=true em HTTPS
#    - ASSET_URL herda APP_URL se existir no ambiente
grep -q '^SESSION_SECURE_COOKIE=' .env || echo 'SESSION_SECURE_COOKIE=true' >> .env
if [ -n "${APP_URL:-}" ] && ! grep -q '^ASSET_URL=' .env; then
  echo "ASSET_URL=${APP_URL}" >> .env
fi

# 7) Permissões para storage e cache (evitam 500 ao gravar view/config)
chown -R www-data:www-data storage bootstrap/cache || true
find storage bootstrap/cache -type d -exec chmod 775 {} \; || true
find storage bootstrap/cache -type f -exec chmod 664 {} \; || true

# 8) Cria symlink do storage para arquivos públicos (não falha se já existir)
php artisan storage:link || true

# 9) Limpa caches antigos e recarrega (garante que o Laravel leia a APP_KEY correta)
php artisan optimize:clear || true
php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

# 10) (Opcional) Rodar migrações/seed
#     - Se o DB não estiver pronto, isso pode falhar; por isso use "|| true" ou crie
#       um pequeno "wait-for-db" aqui, se preferir.
# php artisan migrate --force --seed || true

# 11) Cria o arquivo "installed" (usado por alguns instaladores como o do Krayin)
#     - Sinaliza que a aplicação já passou pelo processo de install
touch storage/app/installed || true

# 12) Entrega o processo para o comando principal (supervisord por padrão no Dockerfile)
#     - "exec" substitui o shell pelo processo, respeitando sinais (graceful stop)
exec "$@"
