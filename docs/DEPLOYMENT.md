# Deployment

Guia completo para publicação do Self Dojo Mobile nas lojas.

## 📱 Preparação Geral

### 1. Configuração do App

```yaml
# pubspec.yaml
name: self_dojo_mobile
description: Self Dojo Mobile App
publish_to: 'none'
version: 1.0.0+1  # version_name+version_code
```

### 2. Ícone do App

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.0

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

```bash
dart run flutter_launcher_icons
```

### 3. Splash Screen

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.3.0

flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash/logo.png
  android_12:
    color: "#FFFFFF"
    image: assets/splash/logo.png
```

```bash
dart run flutter_native_splash:create
```

## 🤖 Android

### Configuração

#### 1. App ID

```kotlin
// android/app/build.gradle
android {
    namespace "com.vcinova.selfdojo"
    
    defaultConfig {
        applicationId "com.vcinova.selfdojo"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

#### 2. Permissões

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Outras permissões necessárias -->
    <!-- <uses-permission android:name="android.permission.CAMERA"/> -->
    
    <application
        android:label="Self Dojo"
        android:icon="@mipmap/ic_launcher">
        <!-- ... -->
    </application>
</manifest>
```

#### 3. ProGuard (Ofuscação)

```
# android/app/proguard-rules.pro
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
```

### Assinatura do App

#### 1. Gerar Keystore

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

#### 2. Configurar Key Properties

```properties
# android/key.properties (NÃO commitar!)
storePassword=<senha>
keyPassword=<senha>
keyAlias=upload
storeFile=upload-keystore.jks
```

#### 3. Configurar Build Gradle

```kotlin
// android/app/build.gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] 
                ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 
                'proguard-rules.pro'
        }
    }
}
```

### Build

```bash
# App Bundle (recomendado para Play Store)
flutter build appbundle --release

# APK
flutter build apk --release

# APK por arquitetura (menor tamanho)
flutter build apk --split-per-abi --release
```

### Publicação na Play Store

1. Acesse [Google Play Console](https://play.google.com/console)
2. Crie um novo app
3. Complete as informações:
   - Título e descrição
   - Screenshots (phone, tablet, TV se aplicável)
   - Ícone (512x512)
   - Feature graphic (1024x500)
   - Política de privacidade
   - Classificação de conteúdo
4. Upload do AAB em Production > Releases
5. Revise e publique

## 🍎 iOS

### Configuração

#### 1. Bundle Identifier

```
# ios/Runner.xcodeproj/project.pbxproj
PRODUCT_BUNDLE_IDENTIFIER = com.vcinova.selfdojo;
```

Ou via Xcode:
1. Abra `ios/Runner.xcworkspace`
2. Runner > Signing & Capabilities
3. Configure Bundle Identifier

#### 2. Info.plist

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <key>CFBundleName</key>
    <string>Self Dojo</string>
    
    <key>CFBundleDisplayName</key>
    <string>Self Dojo</string>
    
    <!-- Permissões (adicione conforme necessário) -->
    <key>NSCameraUsageDescription</key>
    <string>Precisamos da câmera para...</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Precisamos acessar suas fotos para...</string>
</dict>
```

#### 3. Deployment Target

```ruby
# ios/Podfile
platform :ios, '12.0'
```

### Configuração do Xcode

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Selecione Runner no navigator
3. Configure:
   - **General**: Display Name, Bundle Identifier, Version, Build
   - **Signing & Capabilities**: Team, Provisioning Profile
   - **Build Settings**: iOS Deployment Target

### Build

```bash
# Build para release
flutter build ios --release

# Depois, no Xcode:
# Product > Archive
```

### Publicação na App Store

1. Acesse [App Store Connect](https://appstoreconnect.apple.com)
2. Crie um novo app
3. Complete as informações:
   - Nome do app
   - Descrição
   - Keywords
   - Screenshots para todos os dispositivos suportados
   - Ícone (1024x1024)
   - Política de privacidade URL
   - Categoria
   - Classificação etária
4. Upload via Xcode ou Transporter
5. Submeta para review

## 🔧 Flavors (Ambientes)

### Configuração de Flavors

```dart
// lib/core/config/flavor_config.dart
enum Flavor { dev, staging, prod }

class FlavorConfig {
  final Flavor flavor;
  final String name;
  final String apiBaseUrl;
  
  static FlavorConfig? _instance;
  
  factory FlavorConfig({
    required Flavor flavor,
    required String name,
    required String apiBaseUrl,
  }) {
    _instance ??= FlavorConfig._internal(
      flavor: flavor,
      name: name,
      apiBaseUrl: apiBaseUrl,
    );
    return _instance!;
  }
  
  FlavorConfig._internal({
    required this.flavor,
    required this.name,
    required this.apiBaseUrl,
  });
  
  static FlavorConfig get instance => _instance!;
  
  static bool get isDev => _instance?.flavor == Flavor.dev;
  static bool get isStaging => _instance?.flavor == Flavor.staging;
  static bool get isProd => _instance?.flavor == Flavor.prod;
}
```

### Entry Points

```dart
// lib/main_dev.dart
void main() {
  FlavorConfig(
    flavor: Flavor.dev,
    name: 'DEV',
    apiBaseUrl: 'https://api-dev.selfdojo.com',
  );
  runApp(const MyApp());
}

// lib/main_staging.dart
void main() {
  FlavorConfig(
    flavor: Flavor.staging,
    name: 'STAGING',
    apiBaseUrl: 'https://api-staging.selfdojo.com',
  );
  runApp(const MyApp());
}

// lib/main_prod.dart
void main() {
  FlavorConfig(
    flavor: Flavor.prod,
    name: 'PROD',
    apiBaseUrl: 'https://api.selfdojo.com',
  );
  runApp(const MyApp());
}
```

### Build com Flavors

```bash
# Dev
flutter run -t lib/main_dev.dart

# Staging
flutter build apk -t lib/main_staging.dart

# Production
flutter build appbundle -t lib/main_prod.dart --release
```

## 📋 Checklist de Release

### Pré-Release

- [ ] Versão atualizada no pubspec.yaml
- [ ] Changelog atualizado
- [ ] Todos os testes passando
- [ ] Código revisado (code review)
- [ ] Assets otimizados
- [ ] Remover logs de debug
- [ ] Verificar permissões necessárias
- [ ] Testar em dispositivos reais

### Android

- [ ] Keystore configurada e segura
- [ ] App Bundle gerado
- [ ] Testar instalação do APK
- [ ] Screenshots atualizadas
- [ ] Descrição na Play Store atualizada
- [ ] Política de privacidade válida

### iOS

- [ ] Certificados válidos
- [ ] Provisioning profiles configurados
- [ ] Archive gerado
- [ ] Testar no TestFlight
- [ ] Screenshots para todos os devices
- [ ] Informações da App Store atualizadas

### Pós-Release

- [ ] Monitorar crash reports
- [ ] Verificar analytics
- [ ] Coletar feedback dos usuários
- [ ] Tag de versão no git
- [ ] Comunicar time sobre release

## 📚 Recursos

- [Android Deployment](https://docs.flutter.dev/deployment/android)
- [iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)

---

*Última atualização: Janeiro 2026*

