# Firebase App Distribution - Guia de Uso

Este documento descreve como configurar e usar o Firebase App Distribution para distribuir builds do app para testadores.

## 📋 Pré-requisitos

1. **Firebase CLI instalado**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login no Firebase**
   ```bash
   firebase login
   ```

3. **Firebase App Distribution habilitado**
   - Acesse o [Console do Firebase](https://console.firebase.google.com/)
   - Selecione o projeto `self-dojo-mobile`
   - Vá em **App Distribution** no menu lateral
   - Siga as instruções para habilitar o serviço

## 🚀 Uso Rápido

### Android (Windows - PowerShell)

```powershell
# Build debug e distribuir
.\scripts\distribute-android.ps1

# Build release e distribuir
.\scripts\distribute-android.ps1 -Release

# Com grupos específicos
.\scripts\distribute-android.ps1 -Groups "testadores,beta" -Notes "Nova versão com check-in"
```

### Android (Linux/Mac)

```bash
# Dar permissão de execução (primeira vez)
chmod +x scripts/distribute-android.sh

# Build debug e distribuir
./scripts/distribute-android.sh

# Build release e distribuir
./scripts/distribute-android.sh --release

# Com grupos específicos
./scripts/distribute-android.sh --release --groups "testadores,beta" --notes "Nova versão com check-in"
```

### iOS (Mac apenas)

```bash
# Dar permissão de execução (primeira vez)
chmod +x scripts/distribute-ios.sh

# Build e distribuir
./scripts/distribute-ios.sh

# Com grupos específicos
./scripts/distribute-ios.sh --groups "testadores,beta" --notes "Nova versão com check-in"
```

## 📱 Configuração de Grupos de Testadores

### Criar Grupos no Firebase Console

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto `self-dojo-mobile`
3. Vá em **App Distribution** > **Testers & Groups**
4. Clique em **Add group**
5. Crie grupos como:
   - `testadores` - Testadores gerais
   - `beta` - Testadores beta
   - `dev` - Desenvolvedores
   - `qa` - Equipe de QA

### Adicionar Testadores aos Grupos

1. Em **Testers & Groups**, clique no grupo desejado
2. Clique em **Add testers**
3. Adicione emails dos testadores
4. Os testadores receberão um email de convite

## 🔧 Configuração Manual

Se preferir fazer manualmente:

### Android

```bash
# 1. Build do APK
flutter build apk --release

# 2. Distribuir
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:1055602452052:android:f0a676d51bdded4d2d2fc1 \
  --groups "testadores" \
  --release-notes "Versão 1.0.0 - Nova funcionalidade de check-in"
```

### iOS

```bash
# 1. Build do IPA
flutter build ipa

# 2. Distribuir
firebase appdistribution:distribute \
  build/ios/ipa/self_dojo_mobile.ipa \
  --app 1:1055602452052:ios:725ec695964c60ab2d2fc1 \
  --groups "testadores" \
  --release-notes "Versão 1.0.0 - Nova funcionalidade de check-in"
```

## 🤖 CI/CD com GitHub Actions

O projeto inclui um workflow do GitHub Actions para distribuição automática.

### Configuração Inicial

1. **Obter Service Account do Firebase**
   - Acesse [Firebase Console](https://console.firebase.google.com/)
   - Selecione o projeto `self-dojo-mobile`
   - Vá em **Project Settings** (ícone de engrenagem) > **Service Accounts**
   - Clique em **Generate new private key**
   - **IMPORTANTE**: Salve o JSON gerado em local seguro (você não poderá baixá-lo novamente)

2. **Adicionar Secret no GitHub**
   - No repositório, vá em **Settings** > **Secrets and variables** > **Actions**
   - Clique em **New repository secret**
   - **Name**: `FIREBASE_SERVICE_ACCOUNT`
   - **Secret**: Cole o conteúdo **COMPLETO** do JSON do Service Account (incluindo todas as chaves e valores)
   - Clique em **Add secret**

   ⚠️ **Atenção**: O JSON deve ser colado como uma string única, não como objeto JSON formatado.

### Uso do Workflow

#### Via Interface do GitHub

1. Vá em **Actions** > **Firebase App Distribution**
2. Clique em **Run workflow**
3. Selecione:
   - **Platform**: android ou ios
   - **Build type**: debug ou release
   - **Groups**: grupos de testadores (opcional)
   - **Release notes**: notas da release (opcional)
4. Clique em **Run workflow**

#### Via Commit Message

Adicione `[distribute android]` ou `[distribute ios]` na mensagem do commit:

```bash
git commit -m "Nova feature [distribute android]"
```

Isso acionará automaticamente a distribuição ao fazer push.

## 📝 Informações dos Apps

### Android
- **App ID**: `1:1055602452052:android:f0a676d51bdded4d2d2fc1`
- **Package**: `com.vcinova.selfDojoMobile`

### iOS
- **App ID**: `1:1055602452052:ios:725ec695964c60ab2d2fc1`
- **Bundle ID**: `com.vcinova.selfDojoMobile`

## 🔍 Troubleshooting

### Erro: "Input required and not supplied: firebaseServiceAccount"

Este erro ocorre quando o secret `FIREBASE_SERVICE_ACCOUNT` não está configurado no GitHub.

**Solução:**
1. Siga os passos em [Configuração Inicial](#configuração-inicial) acima
2. Certifique-se de que o secret foi adicionado corretamente:
   - Nome exato: `FIREBASE_SERVICE_ACCOUNT` (case-sensitive)
   - Valor: JSON completo do Service Account (uma linha única)
3. Verifique se o secret está visível em **Settings** > **Secrets and variables** > **Actions**

### Erro: "Firebase CLI not found"
```bash
npm install -g firebase-tools
```

### Erro: "Not logged in"
```bash
firebase login
```

### Erro: "App Distribution not enabled"
1. Acesse o Firebase Console
2. Vá em **App Distribution**
3. Siga as instruções para habilitar

### Erro: "Build failed"
- Verifique se todas as dependências estão instaladas: `flutter pub get`
- Verifique se há erros de compilação: `flutter analyze`
- Para Android, verifique se o `google-services.json` está correto
- Para iOS, verifique se os certificados estão configurados

### Erro: "Invalid service account"
- Verifique se o JSON do Service Account está completo
- Certifique-se de que copiou todo o conteúdo do arquivo JSON
- O JSON deve começar com `{` e terminar com `}`

### Testadores não recebem email
- Verifique se os emails estão corretos no grupo
- Verifique a pasta de spam
- Os testadores precisam aceitar o convite primeiro

## 📚 Recursos Adicionais

- [Documentação Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

## 🎯 Boas Práticas

1. **Versionamento**: Sempre atualize a versão no `pubspec.yaml` antes de distribuir
2. **Release Notes**: Sempre adicione notas descritivas sobre o que mudou
3. **Grupos**: Use grupos específicos para diferentes tipos de testadores
4. **Testes**: Teste localmente antes de distribuir
5. **Backup**: Mantenha builds importantes salvos localmente

## 📊 Monitoramento

Acesse o [Firebase Console](https://console.firebase.google.com/) > **App Distribution** para:
- Ver histórico de distribuições
- Ver estatísticas de instalações
- Gerenciar grupos e testadores
- Ver feedback dos testadores

