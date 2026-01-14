# Migrations - Self Dojo Mobile

Este documento lista todas as migrations do banco de dados Supabase.

## Como Aplicar Migrations

### Via SQL Editor do Supabase

1. Acesse o painel do Supabase
2. Vá em **SQL Editor**
3. Clique em **New Query**
4. Cole o conteúdo do arquivo de migration
5. Clique em **Run** (ou `Ctrl+Enter`)

### Via Supabase CLI (Recomendado para produção)

```bash
# Aplicar todas as migrations pendentes
supabase db push

# Ver status das migrations
supabase migration list
```

## Lista de Migrations

### 001_add_photo_url_to_users.sql

**Data:** 2026-01-09  
**Descrição:** Adiciona o campo `photo_url` na tabela `users` para armazenar URLs de fotos de perfil.

**Mudanças:**
- Adiciona coluna `photo_url TEXT` na tabela `users` (se não existir)
- Cria índice para melhorar performance
- Adiciona comentário de documentação

**Como aplicar:**
```sql
-- Execute o conteúdo de supabase/migrations/001_add_photo_url_to_users.sql
```

**Verificar se foi aplicada:**
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'photo_url';
```

---

## Estrutura de Pastas

```
supabase/
├── schema.sql          # Schema completo do banco
└── migrations/         # Migrations incrementais
    └── 001_*.sql       # Migration 001
    └── 002_*.sql       # Migration 002
    └── ...
```

## Convenções

- **Nomenclatura:** `NNN_descricao_da_migration.sql`
- **Numeração:** Sequencial (001, 002, 003...)
- **Idempotência:** Todas as migrations devem ser idempotentes (podem ser executadas múltiplas vezes sem erro)
- **Rollback:** Incluir comentários sobre como reverter se necessário

---

*Última atualização: Janeiro 2026*

