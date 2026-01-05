# Getting Started

Guia completo para configurar o ambiente de desenvolvimento do Self Dojo Mobile.

## 📋 Pré-requisitos

### 1. Flutter SDK

Instale o Flutter SDK versão 3.x ou superior:

```bash
# Windows (usando Chocolatey)
choco install flutter

# Ou download direto
# https://docs.flutter.dev/get-started/install/windows
```

Verifique a instalação:

```bash
flutter --version
flutter doctor
```

### 2. Dart SDK

O Dart SDK já vem incluído com o Flutter, mas verifique:

```bash
dart --version
```

### 3. IDE Recomendada

**VS Code** (recomendado) ou **Android Studio**

#### Extensões VS Code

- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets
- Error Lens
- GitLens

#### Configuração do VS Code

Adicione ao `settings.json`:

```json
{
  "dart.flutterSdkPath": "C:\\flutter",
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.rulers": [80]
  }
}
```

### 4. Android Setup

1. Instale o **Android Studio**
2. Configure o Android SDK:
   - Android SDK Platform 34 (Android 14)
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator

3. Configure as variáveis de ambiente:

```powershell
# PowerShell (adicione ao profile)
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path += ";$env:ANDROID_HOME\tools;$env:ANDROID_HOME\platform-tools"
```

4. Aceite as licenças:

```bash
flutter doctor --android-licenses
```

### 5. iOS Setup (apenas macOS)

1. Instale o **Xcode** (App Store)
2. Configure as ferramentas de linha de comando:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

3. Instale o CocoaPods:

```bash
sudo gem install cocoapods
```

## 🚀 Configuração do Projeto

### 1. Clone o Repositório

```bash
git clone <url-do-repositorio>
cd self-dojo-mobile
```

### 2. Instale as Dependências

```bash
flutter pub get
```

### 3. Configure as Variáveis de Ambiente

Crie o arquivo `.env` na raiz do projeto:

```env
# Ambiente de Desenvolvimento
API_BASE_URL=https://api-dev.selfdojo.com
API_KEY=sua_api_key_aqui

# Firebase (opcional)
FIREBASE_PROJECT_ID=self-dojo-dev
```

### 4. Gere os Arquivos Necessários

Se o projeto usar code generation (build_runner):

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Execute o Projeto

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Escolher dispositivo específico
flutter devices  # Lista dispositivos
flutter run -d <device_id>
```

## 🧪 Verificação da Instalação

Execute o comando para verificar se tudo está configurado:

```bash
flutter doctor -v
```

Saída esperada (todos os itens com ✓):

```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Windows Version
[✓] Android toolchain
[✓] Chrome - develop for the web
[✓] Visual Studio - develop Windows apps
[✓] Android Studio
[✓] VS Code
[✓] Connected device
```

## 🐛 Troubleshooting

### Erro: "Flutter SDK not found"

```bash
flutter config --android-sdk <path>
```

### Erro: "Android license not accepted"

```bash
flutter doctor --android-licenses
```

### Erro: "Pub get failed"

```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Erro: "CocoaPods not installed" (iOS)

```bash
sudo gem install cocoapods
cd ios && pod install
```

## 📚 Próximos Passos

1. Leia a [Arquitetura do Projeto](./ARCHITECTURE.md)
2. Conheça os [Padrões de Código](./CODING_STANDARDS.md)
3. Entenda o [Gerenciamento de Estado](./STATE_MANAGEMENT.md)

---

*Última atualização: Janeiro 2026*

