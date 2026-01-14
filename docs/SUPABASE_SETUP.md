# Configuração do Supabase

Este guia explica como configurar o Supabase para o Self Dojo.

## 1. Criar Projeto no Supabase

1. Acesse [supabase.com](https://supabase.com)
2. Crie uma conta ou faça login
3. Clique em **New Project**
4. Escolha:
   - **Name**: `self-dojo`
   - **Database Password**: Crie uma senha forte
   - **Region**: Escolha a mais próxima (ex: São Paulo)
5. Clique em **Create new project**

## 2. Configurar Credenciais no App

Após criar o projeto:

1. Vá em **Settings** > **API**
2. Copie:
   - **URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJ...`

3. Edite o arquivo `lib/core/config/supabase_config.dart`:

```dart
abstract class SupabaseConfig {
  static const String url = 'https://SEU_PROJECT_ID.supabase.co';
  static const String anonKey = 'SUA_ANON_KEY';
}
```

## 3. Executar Schema SQL

1. Vá em **SQL Editor** no painel do Supabase
2. Clique em **New Query**
3. Cole o conteúdo de `supabase/schema.sql`
4. Clique em **Run** (ou Ctrl+Enter)

## 4. Configurar Storage

1. Vá em **Storage** no painel
2. Clique em **New Bucket**
3. Crie um bucket chamado `avatars`
4. Configure como **Public** para permitir URLs públicas
5. Adicione policies (opcional, para maior segurança):

```sql
-- Permitir upload apenas para usuários autenticados
CREATE POLICY "Users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars');

-- Permitir leitura pública
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');
```

## 5. Configurar RLS (Row Level Security)

O schema já inclui políticas básicas de RLS. Verifique se estão ativas:

1. Vá em **Authentication** > **Policies**
2. Cada tabela deve ter RLS habilitado
3. Revise as policies conforme necessário

## 6. Testar Conexão

Execute o app:

```bash
flutter run
```

Se configurado corretamente, o app deve:
- Criar usuário no Supabase após login com Firebase
- Salvar perfil e dados da academia no PostgreSQL

## Estrutura de Tabelas

| Tabela | Descrição |
|--------|-----------|
| `users` | Perfis de usuários (complementa Firebase Auth) |
| `academies` | Academias registradas |
| `academy_modalities` | Modalidades por academia |
| `belt_configs` | Configuração de graduação personalizada |
| `academy_members` | Membros (alunos, professores) |
| `student_modalities` | Matrículas em modalidades |
| `graduation_history` | Histórico de graduações |
| `student_plans` | Planos de mensalidade |
| `check_ins` | Check-ins de presença |

## Migração Futura

Para migrar do Supabase para PostgreSQL próprio:

```bash
# 1. Exportar dados
pg_dump -h db.xxxxx.supabase.co -U postgres -d postgres > backup.sql

# 2. Importar no novo servidor
psql -h seu-servidor.com -U postgres -d seu_banco < backup.sql
```

## Troubleshooting

### Erro de CORS
Se receber erro de CORS, verifique se a URL está correta no `supabase_config.dart`.

### Erro de Permissão
Verifique se as políticas RLS estão configuradas corretamente para seu caso de uso.

### Dados não salvam
Verifique os logs no painel do Supabase em **Logs** > **Edge Functions Logs**.

