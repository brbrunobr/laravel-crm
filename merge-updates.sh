#!/bin/bash

echo "🔄 Iniciando processo de merge das atualizações..."

# 1. Fazer backup do trabalho atual
echo "📦 Criando backup das alterações atuais..."
git add .
git commit -m "Backup: salvando alterações locais antes do merge"

# 2. Verificar se o remote 'upstream' já existe
if git remote get-url upstream > /dev/null 2>&1; then
    echo "✅ Remote 'upstream' já existe"
else
    echo "➕ Adicionando repositório original como upstream..."
    read -p "Digite a URL do repositório original: " original_repo
    git remote add upstream $original_repo
fi

# 3. Buscar atualizações do repositório original
echo "🔍 Buscando atualizações do repositório original..."
git fetch upstream

# 4. Fazer merge das atualizações
echo "🔀 Fazendo merge das atualizações..."
git merge upstream/main

# 5. Verificar se houve conflitos
if [ $? -eq 0 ]; then
    echo "✅ Merge realizado com sucesso!"
    echo "🚀 Suas alterações foram preservadas e as atualizações foram aplicadas."
else
    echo "⚠️  Conflitos detectados!"
    echo "📝 Resolva os conflitos manualmente e execute:"
    echo "   git add ."
    echo "   git commit -m 'Resolve merge conflicts'"
fi

echo "✨ Processo concluído!"
