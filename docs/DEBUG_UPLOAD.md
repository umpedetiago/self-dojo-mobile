# Debug - Upload de Imagens

Guia para debugar problemas de upload de imagens.

## 🔍 Logs Adicionados

Adicionei logs detalhados no método `uploadFile` do `SupabaseService`. Agora você verá no console:

```
[SupabaseService] Iniciando upload: bucket=avatars, path=profiles/...
[SupabaseService] Tamanho do arquivo: XXX KB
[SupabaseService] Bucket "avatars" encontrado
[SupabaseService] Fazendo upload do arquivo...
[SupabaseService] Upload realizado com sucesso
[SupabaseService] URL pública gerada: https://...
```

Ou em caso de erro:

```
[SupabaseService] ERRO: ...
[SupabaseService] StorageException capturada: statusCode=403, message=...
```

## 🧪 Como Testar

### 1. Execute o app com logs visíveis

```bash
flutter run
```

### 2. Tente fazer upload de uma foto

1. Abra a tela de edição de perfil
2. Selecione uma foto da galeria
3. Clique em "Salvar"
4. **Observe o console** para ver os logs

### 3. Verifique os erros

Os erros agora aparecem:
- **No console** (logs detalhados)
- **Na tela** (SnackBar com mensagem de erro)

## 🔴 Erros Comuns e Soluções

### HandshakeException - Erro de Conexão SSL/TLS

**Erro:**
```
HandshakeException: Connection terminated during handshake
```

**Causa:** Problema de conexão SSL/TLS com o servidor Supabase.

**Possíveis causas:**
1. Problema de rede/conexão instável
2. Firewall ou proxy bloqueando conexões SSL
3. Certificado SSL inválido ou expirado
4. Timeout durante o handshake
5. Problema temporário no servidor Supabase

**Soluções:**

1. **Verificar conexão de internet:**
   - Teste sua conexão com outros apps/sites
   - Tente usar uma rede diferente (WiFi vs dados móveis)

2. **Verificar configuração do Supabase:**
   - Acesse o painel do Supabase
   - Verifique se o projeto está ativo
   - Verifique se há avisos de manutenção

3. **Tentar novamente:**
   - O erro pode ser temporário
   - Aguarde alguns segundos e tente novamente

4. **Verificar firewall/proxy:**
   - Se estiver em rede corporativa, pode haver bloqueio
   - Tente em rede doméstica ou dados móveis

5. **Verificar URL do Supabase:**
   - Confirme que a URL em `supabase_config.dart` está correta
   - Deve ser `https://xxxxx.supabase.co`

### Erro 401 - Não Autenticado

**Log:**
```
[SupabaseService] StorageException capturada: statusCode=401
```

**Causa:** Supabase não reconhece o usuário autenticado.

**Solução:**
- Verifique se está logado no Firebase
- O Supabase Storage precisa de autenticação para aplicar policies
- Configure policies que permitam uploads anônimos OU configure autenticação do Supabase

### Erro 403 - Sem Permissão

**Log:**
```
[SupabaseService] StorageException capturada: statusCode=403
```

**Causa:** Policies do Storage estão bloqueando o upload.

**Solução:**
1. Acesse o painel do Supabase
2. Vá em **Storage** > **Policies**
3. Selecione o bucket `avatars`
4. Adicione policy:

```sql
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');
```

### Erro 404 - Bucket Não Encontrado

**Log:**
```
[SupabaseService] ERRO: Bucket "avatars" não encontrado
```

**Causa:** O bucket `avatars` não existe.

**Solução:**
1. Acesse o painel do Supabase
2. Vá em **Storage**
3. Clique em **New Bucket**
4. Nome: `avatars`
5. Marque como **Public**

### Arquivo Não Aparece no Storage

**Possíveis causas:**
1. Upload falhou silenciosamente (verifique logs)
2. Arquivo foi salvo em path diferente (verifique logs do path)
3. Permissões não permitem visualização (verifique policies)

**Solução:**
- Verifique os logs para ver o path exato usado
- Verifique no painel do Supabase em **Storage** > **avatars**
- Procure pelo path: `profiles/{userId}/avatar_*.jpg`

## 📋 Checklist de Verificação

Antes de testar, verifique:

- [ ] Bucket `avatars` existe no Supabase
- [ ] Bucket está marcado como **Public**
- [ ] Policies de INSERT estão configuradas
- [ ] Policies de SELECT estão configuradas (para visualização)
- [ ] Usuário está autenticado no Firebase
- [ ] Arquivo selecionado existe e não está corrompido
- [ ] Tamanho do arquivo é menor que 5MB

## 🔧 Próximos Passos se Ainda Não Funcionar

1. **Copie os logs completos** do console quando tentar fazer upload
2. **Verifique no Supabase:**
   - Storage > avatars (se o bucket existe)
   - Storage > Policies (se as policies estão ativas)
   - Logs > Edge Functions Logs (se há erros do lado do servidor)

3. **Teste manualmente:**
   - Tente fazer upload de um arquivo pelo painel do Supabase
   - Se funcionar manualmente, o problema é nas policies ou autenticação

## 💡 Dica

Se os logs não aparecerem, pode ser que o erro esteja acontecendo antes do upload. Verifique:
- Se o arquivo está sendo selecionado corretamente
- Se o `_selectedPhoto` não é null
- Se o método `updatePhoto` está sendo chamado

---

*Última atualização: Janeiro 2026*

