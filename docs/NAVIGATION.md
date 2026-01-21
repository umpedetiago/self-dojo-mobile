# Navegação

Guia sobre o sistema de rotas e navegação no Self Dojo Mobile.

## 🗺️ Visão Geral

Este documento descreve as estratégias de navegação declarativa usando **GoRouter**, a solução recomendada para Flutter.

## ⚠️ REGRA IMPORTANTE: Use AppNavigation

**NUNCA** use strings diretamente em `context.go()` ou `context.push()`. **SEMPRE** use a classe `AppNavigation`.

```dart
// ❌ INCORRETO - Não faça isso!
context.go('/academy/manage/$academyId');
context.push('/profile/edit');

// ✅ CORRETO - Use AppNavigation
import 'package:self_dojo_mobile/core/navigation/app_navigation.dart';

AppNavigation.goToManageAcademy(context, academyId: academyId);
AppNavigation.pushToEditProfile(context);
```

## 📦 Classe AppNavigation

A classe `AppNavigation` fornece métodos type-safe para todas as rotas do aplicativo.

### Importação

```dart
import 'package:self_dojo_mobile/core/navigation/app_navigation.dart';
```

### Métodos Disponíveis

#### Auth Routes

```dart
AppNavigation.goToSplash(context);
AppNavigation.goToLogin(context);
AppNavigation.pushToRegister(context);
```

#### Home Routes

```dart
AppNavigation.goToHome(context);
```

#### Profile Routes

```dart
AppNavigation.pushToEditProfile(context);
```

#### Check-in Routes

```dart
AppNavigation.pushToCheckIn(context);
AppNavigation.pushToCheckInHistory(context);
```

#### Academy Routes

```dart
// Navegação básica
AppNavigation.goToCreateAcademy(context);
AppNavigation.goToSelectAcademy(context);
AppNavigation.pushToSearchAcademy(context);

// Gerenciamento de academia
AppNavigation.goToManageAcademy(context); // Sem ID - vai para seleção
AppNavigation.goToManageAcademy(context, academyId: '123'); // Com ID específico

// Funcionalidades da academia
AppNavigation.pushToAcademyModalities(context);
AppNavigation.pushToAcademyStudents(context);
AppNavigation.pushToAcademyTeachers(context);
AppNavigation.pushToAcademySchedules(context);
AppNavigation.pushToAcademySubscription(context);

// Com parâmetros
AppNavigation.pushToEditAcademy(context, academyId: '123');
AppNavigation.pushToAcademyStudentDetail(context, memberId: '456');
AppNavigation.pushToAcademyGraduation(context, type: 'jiuJitsu');

// Solicitações (retorna resultado)
await AppNavigation.pushToAcademyRequests(context);
```

#### Utility Methods

```dart
// Voltar
AppNavigation.pop(context);
AppNavigation.pop(context, resultData); // Com resultado

// Verificar se pode voltar
if (AppNavigation.canPop(context)) {
  AppNavigation.pop(context);
}
```

## 📦 Instalação

```yaml
# pubspec.yaml
dependencies:
  go_router: ^13.0.0
```

## 🚀 Configuração Básica

### Router Configuration

As rotas estão definidas em `lib/core/config/app_router.dart`:

```dart
// lib/core/config/app_router.dart
abstract class AppRoutes {
  // Auth
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  // Home
  static const home = '/home';

  // Academy
  static const createAcademy = '/academy/create';
  static const manageAcademyById = '/academy/manage/:academyId';
  // ... mais rotas
}
```

## 🔀 Tipos de Navegação

### Go (Substitui a stack)

```dart
// Vai para a rota, limpando a stack
AppNavigation.goToHome(context);
AppNavigation.goToLogin(context);
```

### Push (Adiciona à stack)

```dart
// Adiciona à stack (pode voltar)
AppNavigation.pushToEditProfile(context);
AppNavigation.pushToAcademyStudents(context);
```

### Pop (Volta)

```dart
// Volta para a tela anterior
AppNavigation.pop(context);

// Volta com resultado
AppNavigation.pop(context, resultData);

// Verificar se pode voltar
if (AppNavigation.canPop(context)) {
  AppNavigation.pop(context);
}
```

## 💬 Passando Dados

### Via Path Parameters

As rotas com parâmetros são tratadas automaticamente pelos métodos do `AppNavigation`:

```dart
// Rota: /academy/manage/:academyId
AppNavigation.goToManageAcademy(
  context,
  academyId: '123',
);

// Rota: /academy/edit/:academyId
AppNavigation.pushToEditAcademy(
  context,
  academyId: '456',
);

// Rota: /academy/students/:memberId
AppNavigation.pushToAcademyStudentDetail(
  context,
  memberId: '789',
);
```

### Via Resultado (Pop com resultado)

```dart
// Na tela de destino (ex: seleção de cor)
AppNavigation.pop(context, selectedColor);

// Na tela de origem
final selectedColor = await AppNavigation.pushToColorPicker(context);
if (selectedColor != null) {
  // Usar a cor selecionada
}
```

## 🎯 Benefícios de Usar AppNavigation

1. **Type Safety**: Erros de digitação são detectados em tempo de compilação
2. **Refatoração Fácil**: Mudanças nas rotas são centralizadas
3. **Autocomplete**: IDE sugere métodos disponíveis
4. **Documentação**: Cada método tem documentação clara
5. **Consistência**: Todos usam a mesma forma de navegar

## 📝 Adicionando Novas Rotas

1. Adicione a rota em `AppRoutes` (se ainda não existir)
2. Adicione o método correspondente em `AppNavigation`
3. Documente o método
4. Use o método nas telas ao invés de strings

Exemplo:

```dart
// 1. Em AppRoutes (se necessário)
static const newFeature = '/new-feature';

// 2. Em AppNavigation
/// Navega para a nova feature
static void pushToNewFeature(BuildContext context) {
  context.push(AppRoutes.newFeature);
}

// 3. Uso
AppNavigation.pushToNewFeature(context);
```

## 🧪 Testando Navegação

```dart
void main() {
  testWidgets('navigates to profile', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppRoutes.editProfile,
          builder: (context, state) => const EditProfilePage(),
        ),
      ],
    );
    
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
    
    // Simula navegação usando AppNavigation
    AppNavigation.pushToEditProfile(tester.element(find.byType(HomePage)));
    await tester.pumpAndSettle();
    
    expect(find.byType(EditProfilePage), findsOneWidget);
  });
}
```

## 📱 Deep Links

### Android (AndroidManifest.xml)

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data
    android:scheme="https"
    android:host="selfdojo.com"
    android:pathPrefix="/app"/>
</intent-filter>
```

### iOS (Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>selfdojo</string>
    </array>
  </dict>
</array>
```

## ✅ Checklist para Novas Features

Ao criar uma nova tela ou feature:

- [ ] Use `AppNavigation` ao invés de strings
- [ ] Adicione método em `AppNavigation` se necessário
- [ ] Documente o método
- [ ] Teste a navegação

## 📚 Recursos

- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Flutter Navigation](https://docs.flutter.dev/ui/navigation)

---

**Última atualização**: Janeiro 2025
