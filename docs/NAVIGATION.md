# Navegação

Guia sobre o sistema de rotas e navegação no Self Dojo Mobile.

## 🗺️ Visão Geral

Este documento descreve as estratégias de navegação declarativa usando **GoRouter**, a solução recomendada para Flutter.

## 📦 Instalação

```yaml
# pubspec.yaml
dependencies:
  go_router: ^13.0.0
```

## 🚀 Configuração Básica

### Router Configuration

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/profile/:userId',
      name: 'profile',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfilePage(userId: userId);
      },
    ),
  ],
);

// main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
    );
  }
}
```

### Route Constants

```dart
// lib/core/router/routes.dart
abstract class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const profile = '/profile';
  static const settings = '/settings';
  
  // Nested routes
  static const settingsNotifications = '/settings/notifications';
  static const settingsPrivacy = '/settings/privacy';
}
```

## 🔀 Tipos de Navegação

### Push (Adiciona à stack)

```dart
// Por path
context.push('/profile/123');

// Por nome
context.pushNamed(
  'profile',
  pathParameters: {'userId': '123'},
);

// Com query parameters
context.push('/search?query=flutter&page=1');
context.pushNamed(
  'search',
  queryParameters: {'query': 'flutter', 'page': '1'},
);
```

### Go (Substitui a stack)

```dart
// Vai para a rota, limpando a stack
context.go('/home');

// Por nome
context.goNamed('home');
```

### Replace (Substitui a rota atual)

```dart
// Substitui sem adicionar à stack
context.pushReplacement('/home');
```

### Pop (Volta)

```dart
// Volta para a tela anterior
context.pop();

// Volta com resultado
context.pop(resultData);

// Verificar se pode voltar
if (context.canPop()) {
  context.pop();
}
```

## 🏗️ Rotas Aninhadas (Nested Routes)

### Shell Route

```dart
final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);

// MainShell com BottomNavigationBar
class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
  
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }
  
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/search');
      case 2:
        context.go('/profile');
    }
  }
}
```

### Stateful Shell Route (Preserva estado)

```dart
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

## 🔐 Redirecionamento e Guards

### Authentication Redirect

```dart
final appRouter = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authNotifier.isLoggedIn;
    final isLoggingIn = state.matchedLocation == '/login';
    
    // Se não está logado e não está na tela de login
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    
    // Se está logado e está na tela de login
    if (isLoggedIn && isLoggingIn) {
      return '/home';
    }
    
    // Sem redirecionamento
    return null;
  },
  routes: [...],
);
```

### Refresh com Listenable

```dart
// Com Riverpod
final appRouter = GoRouter(
  refreshListenable: authNotifier,
  redirect: (context, state) {
    // Lógica de redirect
  },
  routes: [...],
);

// AuthNotifier como ChangeNotifier
class AuthNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  
  bool get isLoggedIn => _isLoggedIn;
  
  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }
  
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
```

## 🎬 Transições Personalizadas

### Page Transitions

```dart
GoRoute(
  path: '/details',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: const DetailsPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  },
),

// Slide Transition
GoRoute(
  path: '/modal',
  pageBuilder: (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: const ModalPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  },
),
```

## 💬 Passando Dados

### Via Path Parameters

```dart
// Definição
GoRoute(
  path: '/user/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return UserPage(id: id);
  },
),

// Navegação
context.push('/user/123');
```

### Via Query Parameters

```dart
// Definição
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    return SearchPage(query: query);
  },
),

// Navegação
context.push('/search?q=flutter');
```

### Via Extra (Objetos complexos)

```dart
// Definição
GoRoute(
  path: '/details',
  builder: (context, state) {
    final product = state.extra as Product;
    return DetailsPage(product: product);
  },
),

// Navegação
context.push('/details', extra: product);
```

## ⬅️ Resultado ao Voltar

```dart
// Na tela de destino
GoRoute(
  path: '/select-color',
  builder: (context, state) => ColorPickerPage(),
),

// ColorPickerPage
ElevatedButton(
  onPressed: () => context.pop(selectedColor),
  child: Text('Confirmar'),
),

// Na tela de origem
final selectedColor = await context.push<Color>('/select-color');
if (selectedColor != null) {
  // Usar a cor selecionada
}
```

## 🧪 Testando Navegação

```dart
void main() {
  testWidgets('navigates to profile', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    );
    
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
    
    // Simula navegação
    router.push('/profile');
    await tester.pumpAndSettle();
    
    expect(find.byType(ProfilePage), findsOneWidget);
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

## 📚 Recursos

- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Flutter Navigation](https://docs.flutter.dev/ui/navigation)
- [Deep Linking](https://docs.flutter.dev/ui/navigation/deep-linking)

---

*Última atualização: Janeiro 2026*

