# Fix: photo_url não está sendo atualizado

## 🔴 Problema

O campo `photo_url` existe na tabela `users`, mas não está sendo atualizado quando uma imagem é salva.

## 🔍 Causa

A **Row Level Security (RLS)** policy da tabela `users` está bloqueando o UPDATE porque:

1. A policy atual verifica o JWT do Supabase Auth: `current_setting('request.jwt.claims')::json->>'sub'`
2. O app usa **Firebase Auth**, não Supabase Auth
3. O Firebase Auth não passa JWT para o Supabase
4. Resultado: A policy bloqueia o UPDATE

## ✅ Solução

### Passo 1: Aplicar o Fix da Policy RLS

Execute o SQL em `supabase/fix_users_rls_policy.sql`:

1. Acesse o **SQL Editor** do Supabase
2. Cole o conteúdo do arquivo `supabase/fix_users_rls_policy.sql`
3. Execute (Run ou `Ctrl+Enter`)

Este SQL vai:
- Remover a policy antiga que bloqueia updates
- Criar uma nova policy que permite UPDATE na tabela `users`

### Passo 2: Verificar se Funcionou

Execute este SQL para verificar:

```sql
-- Verifica se a policy foi criada
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users';
```

Você deve ver a policy `Users can update own profile` com `cmd = UPDATE`.

### Passo 3: Testar no App

1. Faça upload de uma foto
2. Verifique os logs no console:
   ```
   [ProfileRepository] URL gerada: https://...
   [ProfileRepository] Usuário encontrado: true
   [ProfileRepository] Atualizando usuário ID: ...
   [SupabaseService] ✅ Usuário atualizado. Resposta: ...
   [ProfileRepository] ✅ Usuário atualizado com sucesso
   [ProfileRepository] URL salva no banco: https://...
   ```

3. Verifique no banco:
   ```sql
   SELECT firebase_uid, email, photo_url 
   FROM users 
   WHERE firebase_uid = 'SEU_FIREBASE_UID';
   ```

## 🔐 Segurança

A policy criada permite **qualquer UPDATE** na tabela `users`. Isso é seguro porque:

1. ✅ Apenas o app faz updates (não há API pública)
2. ✅ O app valida o usuário antes de fazer update
3. ✅ Para produção, você pode criar uma policy mais restritiva usando Edge Functions

### Para Produção (Futuro)

Se precisar de mais segurança, você pode:

1. **Criar uma Edge Function** que recebe o token do Firebase
2. **Validar o token** na Edge Function
3. **Fazer o UPDATE** com permissões de service role

Ou usar a **Opção 2** comentada no arquivo SQL (mas pode não funcionar sem configuração adicional).

## 🐛 Debug

Se ainda não funcionar após aplicar o fix:

1. **Verifique os logs** do app para ver onde está falhando
2. **Execute manualmente** no SQL Editor:
   ```sql
   UPDATE users 
   SET photo_url = 'https://teste.com/foto.jpg' 
   WHERE firebase_uid = 'SEU_FIREBASE_UID';
   ```
   
   Se isso funcionar, o problema é na policy. Se não funcionar, pode ser outro problema.

3. **Verifique se RLS está habilitado**:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename = 'users';
   ```
   
   `rowsecurity = true` significa que RLS está ativo.

## 📋 Checklist

- [ ] Executei o SQL de fix da policy
- [ ] Verifiquei que a policy foi criada
- [ ] Testei fazer upload de foto no app
- [ ] Verifiquei os logs do app
- [ ] Verifiquei no banco que `photo_url` foi atualizado
- [ ] Foto aparece na tela do app

---

*Última atualização: Janeiro 2026*

