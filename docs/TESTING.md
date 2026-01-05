# Testes

Guia completo de testes para o Self Dojo Mobile.

## 📊 Pirâmide de Testes

```
        /\
       /  \
      / E2E \        (poucos)
     /--------\
    /Integration\    (alguns)
   /--------------\
  /   Unit Tests    \ (muitos)
 /--------------------\
```

| Tipo | Cobertura | Velocidade | Custo |
|------|-----------|------------|-------|
| Unit | Alto | Rápido | Baixo |
| Widget | Médio | Médio | Médio |
| Integration | Baixo | Lento | Alto |

## 🧪 Unit Tests

Testam ViewModels, Repositories, Services e lógica de negócios isoladamente.

### Testando ViewModels

```dart
// test/ui/features/home/view_models/home_viewmodel_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  late HomeViewModel viewModel;
  late MockItemRepository mockRepository;
  
  setUp(() {
    mockRepository = MockItemRepository();
    viewModel = HomeViewModel(itemRepository: mockRepository);
  });
  
  tearDown(() {
    viewModel.dispose();
  });
  
  group('HomeViewModel', () {
    test('initial state is correct', () {
      expect(viewModel.items, isEmpty);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.selectedItem, isNull);
    });
    
    test('loadItems updates items on success', () async {
      // Arrange
      final testItems = [
        Item(id: '1', name: 'Item 1'),
        Item(id: '2', name: 'Item 2'),
      ];
      
      when(() => mockRepository.getItems())
          .thenAnswer((_) async => Result.success(testItems));
      
      // Act
      await viewModel.loadItems.execute();
      
      // Assert
      expect(viewModel.items, testItems);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isNull);
    });
    
    test('loadItems sets error on failure', () async {
      // Arrange
      when(() => mockRepository.getItems())
          .thenAnswer((_) async => Result.failure(
            Failure(message: 'Network error'),
          ));
      
      // Act
      await viewModel.loadItems.execute();
      
      // Assert
      expect(viewModel.items, isEmpty);
      expect(viewModel.error, 'Network error');
    });
    
    test('selectItem updates selectedItem', () {
      final item = Item(id: '1', name: 'Test');
      
      viewModel.selectItem(item);
      
      expect(viewModel.selectedItem, item);
    });
    
    test('notifies listeners on state change', () {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);
      
      viewModel.selectItem(Item(id: '1', name: 'Test'));
      
      expect(notifyCount, 1);
    });
  });
  
  group('loadItems Command', () {
    test('running is true while loading', () async {
      when(() => mockRepository.getItems())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return Result.success([]);
          });
      
      final future = viewModel.loadItems.execute();
      
      expect(viewModel.loadItems.running, isTrue);
      
      await future;
      
      expect(viewModel.loadItems.running, isFalse);
    });
    
    test('result contains data on success', () async {
      final items = [Item(id: '1', name: 'Test')];
      
      when(() => mockRepository.getItems())
          .thenAnswer((_) async => Result.success(items));
      
      await viewModel.loadItems.execute();
      
      expect(viewModel.loadItems.result?.isSuccess, isTrue);
    });
  });
}
```

### Testando Repositories

```dart
// test/data/repositories/user_repository_impl_test.dart
void main() {
  late UserRepositoryImpl repository;
  late MockApiService mockApiService;
  late MockStorageService mockStorageService;
  
  setUp(() {
    mockApiService = MockApiService();
    mockStorageService = MockStorageService();
    repository = UserRepositoryImpl(
      apiService: mockApiService,
      storageService: mockStorageService,
    );
  });
  
  group('UserRepositoryImpl', () {
    group('getUser', () {
      const tUserId = '123';
      final tUserApiModel = UserApiModel(
        id: tUserId,
        full_name: 'Test User',
        email_address: 'test@test.com',
      );
      
      test('returns cached user if available', () async {
        // Arrange
        when(() => mockStorageService.getCachedUser(tUserId))
            .thenAnswer((_) async => tUserApiModel);
        
        // Act
        final result = await repository.getUser(tUserId);
        
        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          onSuccess: (user) {
            expect(user.id, tUserId);
            expect(user.name, 'Test User');
          },
          onFailure: (_) => fail('Should be success'),
        );
        
        verifyNever(() => mockApiService.get(any()));
      });
      
      test('fetches from API when cache is empty', () async {
        // Arrange
        when(() => mockStorageService.getCachedUser(tUserId))
            .thenAnswer((_) async => null);
        when(() => mockApiService.get('/users/$tUserId'))
            .thenAnswer((_) async => tUserApiModel.toJson());
        when(() => mockStorageService.cacheUser(any()))
            .thenAnswer((_) async {});
        
        // Act
        final result = await repository.getUser(tUserId);
        
        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockApiService.get('/users/$tUserId')).called(1);
        verify(() => mockStorageService.cacheUser(any())).called(1);
      });
      
      test('returns failure on API error', () async {
        // Arrange
        when(() => mockStorageService.getCachedUser(tUserId))
            .thenAnswer((_) async => null);
        when(() => mockApiService.get('/users/$tUserId'))
            .thenThrow(ApiException(message: 'Not found', code: '404'));
        
        // Act
        final result = await repository.getUser(tUserId);
        
        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          onSuccess: (_) => fail('Should be failure'),
          onFailure: (failure) {
            expect(failure.message, 'Not found');
          },
        );
      });
    });
  });
}
```

### Testando Models

```dart
// test/data/models/user_api_model_test.dart
void main() {
  group('UserApiModel', () {
    const tUserApiModel = UserApiModel(
      id: '123',
      full_name: 'Test User',
      email_address: 'test@test.com',
      avatar_url: 'https://example.com/avatar.png',
    );
    
    final tUserJson = {
      'id': '123',
      'full_name': 'Test User',
      'email_address': 'test@test.com',
      'avatar_url': 'https://example.com/avatar.png',
    };
    
    test('fromJson creates correct model', () {
      final result = UserApiModel.fromJson(tUserJson);
      
      expect(result.id, tUserApiModel.id);
      expect(result.full_name, tUserApiModel.full_name);
      expect(result.email_address, tUserApiModel.email_address);
    });
    
    test('toJson returns correct map', () {
      final result = tUserApiModel.toJson();
      
      expect(result, tUserJson);
    });
    
    test('toDomain converts to User correctly', () {
      final user = tUserApiModel.toDomain();
      
      expect(user.id, '123');
      expect(user.name, 'Test User');  // Mapped from full_name
      expect(user.email, 'test@test.com');  // Mapped from email_address
      expect(user.avatarUrl, 'https://example.com/avatar.png');
    });
  });
}
```

## 🎨 Widget Tests

Testam widgets e suas interações com ViewModels.

### Testando Views com ViewModel

```dart
// test/ui/features/home/widgets/home_screen_test.dart
void main() {
  late MockItemRepository mockRepository;
  
  setUp(() {
    mockRepository = MockItemRepository();
  });
  
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<ItemRepository>.value(value: mockRepository),
        ],
        child: const HomeScreen(),
      ),
    );
  }
  
  group('HomeScreen', () {
    testWidgets('shows loading indicator while loading', (tester) async {
      // Arrange
      when(() => mockRepository.getItems())
          .thenAnswer((_) async {
            await Future.delayed(const Duration(seconds: 1));
            return Result.success([]);
          });
      
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('shows items when loaded', (tester) async {
      // Arrange
      final items = [
        Item(id: '1', name: 'Item 1'),
        Item(id: '2', name: 'Item 2'),
      ];
      
      when(() => mockRepository.getItems())
          .thenAnswer((_) async => Result.success(items));
      
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
    
    testWidgets('shows error message on failure', (tester) async {
      // Arrange
      when(() => mockRepository.getItems())
          .thenAnswer((_) async => Result.failure(
            Failure(message: 'Network error'),
          ));
      
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.textContaining('Network error'), findsOneWidget);
    });
    
    testWidgets('tapping item calls selectItem', (tester) async {
      // Arrange
      final items = [Item(id: '1', name: 'Item 1')];
      
      when(() => mockRepository.getItems())
          .thenAnswer((_) async => Result.success(items));
      
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Item 1'));
      await tester.pump();
      
      // Assert - verificar navegação ou mudança de estado
    });
    
    testWidgets('refresh button triggers reload', (tester) async {
      // Arrange
      when(() => mockRepository.getItems())
          .thenAnswer((_) async => Result.success([]));
      
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      
      // Assert
      verify(() => mockRepository.getItems()).called(2); // inicial + refresh
    });
  });
}
```

### Testando Formulários

```dart
// test/ui/features/auth/widgets/login_screen_test.dart
void main() {
  late MockAuthRepository mockAuthRepository;
  
  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });
  
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Provider<AuthRepository>.value(
        value: mockAuthRepository,
        child: const LoginScreen(),
      ),
    );
  }
  
  group('LoginScreen', () {
    testWidgets('login button is disabled when form is invalid', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      
      expect(button.onPressed, isNull);
    });
    
    testWidgets('login button is enabled when form is valid', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      
      await tester.enterText(
        find.byKey(const Key('email-field')),
        'test@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password-field')),
        '123456',
      );
      await tester.pump();
      
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      
      expect(button.onPressed, isNotNull);
    });
    
    testWidgets('shows error message on login failure', (tester) async {
      when(() => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => Result.failure(
        Failure(message: 'Credenciais inválidas'),
      ));
      
      await tester.pumpWidget(createWidgetUnderTest());
      
      await tester.enterText(
        find.byKey(const Key('email-field')),
        'test@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password-field')),
        '123456',
      );
      await tester.pump();
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      expect(find.text('Credenciais inválidas'), findsOneWidget);
    });
  });
}
```

## 🔗 Integration Tests

Testam o app completo em um dispositivo real ou emulador.

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

### Teste de Fluxo Completo

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Login Flow', () {
    testWidgets('user can login successfully', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // Verifica tela de login
      expect(find.byType(LoginScreen), findsOneWidget);
      
      // Preenche formulário
      await tester.enterText(
        find.byKey(const Key('email-field')),
        'test@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password-field')),
        'password123',
      );
      
      // Clica no botão de login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Verifica navegação para home
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

### Executando

```bash
flutter test integration_test/app_test.dart
```

## 📈 Cobertura de Testes

```bash
# Gera coverage
flutter test --coverage

# Visualiza com lcov
genhtml coverage/lcov.info -o coverage/html
```

### Metas de Cobertura

| Camada | Meta |
|--------|------|
| ViewModels | 90%+ |
| Repositories | 85%+ |
| Models | 80%+ |
| Services | 75%+ |
| Widgets | 60%+ |

## 🛠️ Ferramentas

### Mocktail

```yaml
dev_dependencies:
  mocktail: ^1.0.0
```

```dart
// Criar mock
class MockUserRepository extends Mock implements UserRepository {}

// Stub
when(() => mock.getUser(any())).thenAnswer(
  (_) async => Result.success(testUser),
);

// Verify
verify(() => mock.getUser('123')).called(1);
```

### Registrar Fallback Values

```dart
// test/helpers/register_fallbacks.dart
void registerFallbackValues() {
  registerFallbackValue(FakeUser());
  registerFallbackValue(FakeLoginCredentials());
}

class FakeUser extends Fake implements User {}
class FakeLoginCredentials extends Fake implements LoginCredentials {}

// No setUp
setUpAll(() {
  registerFallbackValues();
});
```

## 📋 Checklist

- [ ] Testes unitários para ViewModels
- [ ] Testes unitários para Repositories
- [ ] Testes unitários para Models
- [ ] Testes de widget para telas principais
- [ ] Testes de integração para fluxos críticos
- [ ] Cobertura mínima atingida
- [ ] CI executando testes automaticamente

## 📚 Recursos

- [Flutter Testing](https://docs.flutter.dev/testing)
- [Mocktail Package](https://pub.dev/packages/mocktail)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

---

*Última atualização: Janeiro 2026*
