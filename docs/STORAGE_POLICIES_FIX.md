# Fix: Erro 403 - Row Level Security Policy

## 🔴 Erro Atual

```
StorageException: statusCode=403, message=new row violates row-level security policy
```

## ✅ Solução Rápida

Este erro acontece porque as **policies do Storage estão bloqueando o upload**. Siga estes passos:

### 1. Acesse o Painel do Supabase

1. Vá para [supabase.com](https://supabase.com)
2. Faça login
3. Selecione seu projeto

### 2. Vá para Storage Policies

1. No menu lateral, clique em **Storage**
2. Clique no bucket **`avatars`**
3. Vá na aba **Policies**

### 3. Remova Policies Restritivas (se existirem)

Se houver policies que bloqueiam uploads, você pode:
- **Remover temporariamente** para testar
- **Ou criar novas policies** conforme abaixo

### 4. Crie as Policies Corretas

No **SQL Editor** do Supabase, execute este SQL:

```sql
-- Remove policies antigas se existirem (opcional)
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload avatars" ON storage.objects;

-- Policy para permitir upload de qualquer pessoa (público)
-- ⚠️ Use esta se você não está usando Supabase Auth
CREATE POLICY "Anyone can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars');

-- Policy para permitir leitura pública
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Policy para permitir atualização (para sobrescrever arquivos)
CREATE POLICY "Anyone can update avatars"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars');

-- Policy para permitir deleção
CREATE POLICY "Anyone can delete avatars"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars');
```

### 5. Verifique se Funcionou

1. Execute o SQL acima
2. Tente fazer upload novamente no app
3. Se ainda der erro, verifique os logs

## 🔍 Verificar Policies Existentes

Para ver quais policies já existem:

```sql
SELECT * FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';
```

## 🛡️ Alternativa Mais Segura (Se Usar Supabase Auth)

Se você estiver usando Supabase Auth (não apenas Firebase), use estas policies:

```sql
-- Policy para upload apenas de usuários autenticados
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Policy para leitura pública
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Policy para atualização
CREATE POLICY "Authenticated users can update avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

-- Policy para deleção
CREATE POLICY "Authenticated users can delete avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');
```

**⚠️ Nota:** Se você está usando apenas Firebase Auth (não Supabase Auth), use a primeira opção (público).

## 📋 Checklist

- [ ] Acessei o painel do Supabase
- [ ] Executei o SQL para criar as policies
- [ ] Verifiquei que as policies foram criadas
- [ ] Testei o upload novamente no app
- [ ] Upload funcionou ✅

## 🐛 Se Ainda Não Funcionar

1. **Verifique se o bucket está público:**
   - Storage > avatars > Settings
   - Marque "Public bucket" como ✅

2. **Verifique se RLS está habilitado:**
   - Storage > avatars > Settings
   - RLS deve estar habilitado, mas as policies devem permitir acesso

3. **Teste manualmente:**
   - Tente fazer upload de um arquivo pelo painel do Supabase
   - Se funcionar manualmente, o problema é nas policies

4. **Verifique os logs:**
   - Storage > Logs
   - Veja se há erros relacionados

---

*Última atualização: Janeiro 2026*

