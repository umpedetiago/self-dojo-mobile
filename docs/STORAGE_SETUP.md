# Configuração do Storage - Upload de Imagens

Este guia explica como configurar o Supabase Storage para permitir upload de imagens de perfil.

## 🔧 Problema Identificado

O upload de imagens estava falhando porque:
1. O bucket `avatars` pode não estar configurado corretamente
2. As policies do Storage podem estar bloqueando uploads
3. O método de upload não tinha tratamento adequado de erros

## ✅ Correções Implementadas

### 1. Melhorias no `SupabaseService.uploadFile()`

- ✅ Verificação de existência do arquivo
- ✅ Validação de tamanho (máximo 5MB)
- ✅ Tratamento de arquivos duplicados (remove e re-upload)
- ✅ Mensagens de erro mais descritivas
- ✅ Tratamento específico de erros do Storage (401, 403, 413)

### 2. Código Atualizado

```dart
Future<Result<String>> uploadFile({
  required String bucket,
  required String path,
  required File file,
}) async {
  // Validações
  // Upload com tratamento de duplicatas
  // Retorna URL pública
}
```

## 📋 Configuração no Supabase

### Passo 1: Criar o Bucket `avatars`

1. Acesse o painel do Supabase
2. Vá em **Storage**
3. Clique em **New Bucket**
4. Configure:
   - **Name**: `avatars`
   - **Public bucket**: ✅ **SIM** (marcado)
   - **File size limit**: 5 MB (ou maior se necessário)
   - **Allowed MIME types**: `image/jpeg, image/png, image/webp`

### Passo 2: Configurar Policies do Storage

**⚠️ IMPORTANTE:** Se você receber erro `403: new row violates row-level security policy`, significa que as policies estão bloqueando o upload. Configure as policies abaixo.

As policies controlam quem pode fazer upload/download. Para o bucket `avatars`:

#### Opção A: Público (Mais Simples - Recomendado para MVP)

Permite upload e download para qualquer usuário (mesmo não autenticado):

```sql
-- Policy para permitir upload de qualquer pessoa (público)
CREATE POLICY "Anyone can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars');

-- Policy para permitir leitura pública
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Policy para permitir atualização (para sobrescrever)
CREATE POLICY "Anyone can update avatars"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars');

-- Policy para permitir deleção
CREATE POLICY "Anyone can delete avatars"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars');
```

**Nota:** Esta configuração permite uploads sem autenticação. Se você quiser mais segurança, use a Opção B.

#### Opção A2: Apenas Autenticados (Recomendado se usar Supabase Auth)

Se você estiver usando Supabase Auth (não apenas Firebase):

```sql
-- Policy para permitir upload de usuários autenticados
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Policy para permitir leitura pública
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Policy para permitir atualização
CREATE POLICY "Authenticated users can update avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

-- Policy para permitir deleção
CREATE POLICY "Authenticated users can delete avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');
```

#### Opção B: Baseado em Firebase UID (Mais Seguro - Requer Configuração)

Permite upload apenas para o próprio usuário. **Esta opção requer configuração adicional** para sincronizar Firebase Auth com Supabase Auth.

```sql
-- Policy para upload baseado no path (contém o firebase_uid)
CREATE POLICY "Users can upload own avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy para leitura pública
CREATE POLICY "Public can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');
```

**⚠️ Nota:** Esta opção requer que o Supabase Auth esteja sincronizado com o Firebase Auth, o que pode ser complexo. Para MVP, use a Opção A.

### Passo 3: Verificar Configuração

1. No painel do Supabase, vá em **Storage** > **Policies**
2. Selecione o bucket `avatars`
3. Verifique se as policies estão ativas
4. Teste fazendo upload manual de um arquivo pelo painel

## 🧪 Testando o Upload

### 1. Verificar Logs

Quando fizer upload pelo app, verifique os logs:

```bash
flutter run
```

Procure por mensagens como:
- ✅ `Upload realizado com sucesso`
- ❌ `Erro no upload: ...`
- ❌ `Sem permissão para fazer upload`

### 2. Verificar no Supabase

1. Após tentar fazer upload, vá em **Storage** > **avatars**
2. Verifique se o arquivo foi criado em `profiles/{userId}/avatar_*.jpg`
3. Clique no arquivo e verifique se a URL pública está funcionando

### 3. Erros Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| `401 Unauthorized` | Usuário não autenticado | Verificar se Firebase Auth está funcionando |
| `403 Forbidden` | Policy bloqueando | Verificar policies do Storage |
| `409 Conflict` | Arquivo já existe | Código já trata isso automaticamente |
| `413 Payload Too Large` | Arquivo muito grande | Reduzir tamanho da imagem |

## 🔐 Segurança

### Recomendações

1. **Limite de tamanho**: Configure limite de 5MB no bucket
2. **Tipos permitidos**: Apenas imagens (JPEG, PNG, WebP)
3. **Validação no app**: O código já valida tamanho antes do upload
4. **CDN**: O Supabase já fornece CDN para as URLs públicas

### Para Produção

Considere implementar:
- [ ] Validação de tipo MIME no servidor
- [ ] Redimensionamento automático de imagens
- [ ] Watermark para imagens públicas
- [ ] Rate limiting para uploads

## 📝 Notas Importantes

1. **Firebase Auth vs Supabase Auth**: 
   - O app usa Firebase Auth para autenticação
   - O Supabase Storage precisa de autenticação para aplicar policies
   - A solução atual usa policies públicas ou baseadas em `authenticated` role

2. **URLs Públicas**:
   - URLs geradas por `getPublicUrl()` são permanentes
   - Não expiram automaticamente
   - Podem ser compartilhadas livremente

3. **Custos**:
   - Uploads contam para o limite de Storage do plano
   - Verifique o plano do Supabase para limites

## 🐛 Troubleshooting

### Upload não funciona

1. Verifique se o bucket `avatars` existe
2. Verifique se está marcado como público
3. Verifique as policies no painel do Supabase
4. Verifique os logs do app para mensagens de erro específicas

### Erro 401/403

1. Verifique se o usuário está autenticado no Firebase
2. Verifique se as policies permitem `authenticated` users
3. Tente fazer upload manual pelo painel do Supabase

### Arquivo não aparece

1. Verifique o path gerado: `profiles/{userId}/avatar_*.jpg`
2. Verifique se o `userId` está correto (Firebase UID)
3. Verifique se há erros nos logs do Supabase

---

*Última atualização: Janeiro 2026*

