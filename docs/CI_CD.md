# CI/CD

Guia de Integração e Entrega Contínua para o Self Dojo Mobile.

## 🔄 Visão Geral

O pipeline CI/CD automatiza build, testes e deploy do aplicativo.

## 🛠️ GitHub Actions

### Workflow de CI

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Analyze
        run: flutter analyze
      
      - name: Format check
        run: dart format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  build-android:
    needs: [analyze, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: [analyze, test]
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
```

### Deploy para Play Store

```yaml
# .github/workflows/deploy-android.yml
name: Deploy Android

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
      
      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" >> android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
          echo "storeFile=keystore.jks" >> android/key.properties
      
      - name: Build App Bundle
        run: flutter build appbundle --release
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.vcinova.selfdojo
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal
```

## 🔐 Secrets Necessários

| Secret | Descrição |
|--------|-----------|
| `KEYSTORE_BASE64` | Keystore em base64 |
| `KEYSTORE_PASSWORD` | Senha do keystore |
| `KEY_PASSWORD` | Senha da key |
| `KEY_ALIAS` | Alias da key |
| `PLAY_STORE_SERVICE_ACCOUNT` | JSON da service account |
| `MATCH_PASSWORD` | Senha do Fastlane Match (iOS) |

## 🍎 Fastlane (iOS)

### Setup

```ruby
# ios/Gemfile
source "https://rubygems.org"
gem "fastlane"
```

### Fastfile

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Build and deploy to TestFlight"
  lane :beta do
    setup_ci
    
    match(
      type: "appstore",
      readonly: true
    )
    
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
end
```

## 📊 Codemagic (Alternativa)

```yaml
# codemagic.yaml
workflows:
  android-workflow:
    name: Android Build
    environment:
      flutter: stable
      java: 17
    scripts:
      - flutter packages pub get
      - flutter test
      - flutter build appbundle --release
    artifacts:
      - build/**/outputs/**/*.aab
    publishing:
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
        track: internal
```

## 📋 Boas Práticas

1. **Versionamento semântico** (MAJOR.MINOR.PATCH)
2. **Tags para releases** (`git tag v1.0.0`)
3. **Branch protection** no main
4. **Code review** obrigatório
5. **Testes automáticos** antes do merge
6. **Ambiente de staging** antes de produção

---

*Última atualização: Janeiro 2026*

