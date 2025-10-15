# Resumo da Migração v2.1.4 → v2.1.5

## Status: ✅ CONCLUÍDA COM SUCESSO

## Data da Migração
15 de Outubro de 2025

## Versão Anterior
v2.1.4 (fork personalizado com branding Delta Ai)

## Versão Atual
v2.1.5 (mantendo todas as personalizações Delta Ai)

## Mudanças Aplicadas do Upstream v2.1.5

### 1. Correções de Compatibilidade com Prefixo de Banco de Dados
Todas as mudanças na v2.1.5 foram relacionadas ao suporte aprimorado para prefixos de tabela de banco de dados (#2355).

#### Arquivos Modificados:

**packages/Webkul/Core/src/Core.php**
- Atualizado `KRAYIN_VERSION` de '2.1.4' para '2.1.5'

**packages/Webkul/Activity/src/Repositories/ActivityRepository.php**
- Adicionado `$tablePrefix = \DB::getTablePrefix();`
- Modificado query raw para usar prefixo: `IF('.$tablePrefix.'activities.is_done, "done", "")`

**packages/Webkul/Admin/src/DataGrids/Product/ProductDataGrid.php**
- Modificadas 3 queries SQL para incluir prefixo de tabela:
  - `SUM('.$tablePrefix.'product_inventories.in_stock)`
  - `SUM('.$tablePrefix.'product_inventories.allocated)`
  - `SUM('.$tablePrefix.'product_inventories.in_stock - '.$tablePrefix.'product_inventories.allocated)`

**packages/Webkul/Admin/src/Helpers/Reporting/Lead.php**
- Modificado query de agregação para usar prefixo: `SUM('.\DB::getTablePrefix()."$valueColumn)`

**CHANGELOG.md**
- Adicionada entrada da versão 2.1.5

## Personalizações Delta Ai Mantidas

Todas as seguintes personalizações foram preservadas intactas:

### 1. Arquivos de Idioma (14 arquivos)
- Admin: ar, en, es, fa, pt_BR, tr, vi
- Installer: ar, en, es, fa, pt_BR, tr, vi
- Todos com referências "Delta Ai" ao invés de "Krayin"/"Webkul"

### 2. Templates (3 arquivos)
- `packages/Webkul/Admin/src/Resources/views/sessions/login.blade.php`
- `packages/Webkul/Admin/src/Resources/views/components/layouts/sidebar/mobile/index.blade.php`
- `packages/Webkul/Installer/src/Resources/views/installer/index.blade.php`

### 3. Assets
- `packages/Webkul/Installer/src/Resources/assets/images/logo.svg`

### 4. Configurações
- `composer.json` - Descrição "Delta Ai CRM"
- `packages/Webkul/Admin/src/Config/core_config.php`

### 5. Documentação
- `CUSTOMIZATION_CHANGELOG.md` - Documentação completa das personalizações
- `merge-updates.sh` - Script para futuros merges
- `.gitignore` - Configurações customizadas

## Validações Realizadas

✅ Sintaxe PHP verificada em todos os arquivos modificados
✅ Comparação com upstream v2.1.5 confirma que apenas customizações Delta Ai diferem
✅ Versão do sistema atualizada para 2.1.5
✅ CHANGELOG.md atualizado
✅ Nenhum conflito detectado
✅ Todas as personalizações Delta Ai preservadas

## Arquivos Que Diferem do Upstream v2.1.5

Apenas arquivos personalizados com branding Delta Ai (25 arquivos):
- Arquivos de idioma (Admin e Installer)
- Templates de login e instalador
- Logo e assets
- Configurações e documentação personalizada

## Próximos Passos Recomendados

1. ✅ Merge/Pull Request criado com as mudanças
2. 📋 Revisar as mudanças no PR
3. 🧪 Testar instalação com prefixo de banco de dados (se aplicável)
4. 🧪 Testar dashboard e funcionalidades principais
5. 🚀 Aprovar e fazer merge do PR quando validado

## Notas Técnicas

- A migração foi minimal e cirúrgica - apenas 5 arquivos modificados
- Nenhum arquivo personalizado foi afetado pelas mudanças upstream
- As correções de prefixo DB melhoram a compatibilidade quando prefixos personalizados são usados
- O script `merge-updates.sh` pode ser usado para futuras migrações

## Comandos Git para Verificar Diferenças

```bash
# Ver todas as diferenças com v2.1.5
git diff v2.1.5 HEAD

# Ver apenas arquivos modificados
git diff v2.1.5 HEAD --name-only

# Ver estatísticas
git diff v2.1.5 HEAD --stat
```

## Conclusão

✅ A migração para v2.1.5 foi concluída com sucesso
✅ Todas as personalizações Delta Ai foram mantidas
✅ Nenhum conflito ou perda de dados
✅ Sistema pronto para uso na versão 2.1.5
