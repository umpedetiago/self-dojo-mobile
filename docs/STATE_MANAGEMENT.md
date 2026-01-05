# Gerenciamento de Estado

Guia sobre estratégias de gerenciamento de estado no Self Dojo Mobile.

## 📊 Visão Geral

O projeto utiliza a abordagem **MVVM com ChangeNotifier**, seguindo as recomendações oficiais do Flutter. ViewModels gerenciam o estado e notificam as Views através do padrão Observer.

## 🎯 Tipos de Estado

| Tipo | Descrição | Onde Gerenciar |
|------|-----------|----------------|
| **Ephemeral** | Estado local de um widget | `setState` no próprio widget |
| **Feature State** | Estado de uma tela/feature | ViewModel da feature |
| **App State** | Estado compartilhado global | ViewModel global via Provider |

## 🏗️ Padrão MVVM com ChangeNotifier

### ViewModel Base

```dart
// core/ui/base_viewmodel.dart
abstract class BaseViewModel extends ChangeNotifier {
  bool _isDisposed = false;
  
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
```

### ViewModel Completa

```dart
// ui/features/auth/view_models/login_viewmodel.dart
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository {
    login = Command1(_login);
  }
  
  final AuthRepository _authRepository;
  
  // Estado
  String _email = '';
  String get email => _email;
  
  String _password = '';
  String get password => _password;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Commands
  late final Command1<User, LoginCredentials> login;
  
  // Actions
  void setEmail(String value) {
    _email = value;
    _errorMessage = null;
    notifyListeners();
  }
  
  void setPassword(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<Result<User>> _login(LoginCredentials credentials) async {
    final result = await _authRepository.login(
      email: credentials.email,
      password: credentials.password,
    );
    
    result.fold(
      onSuccess: (_) => _errorMessage = null,
      onFailure: (failure) => _errorMessage = failure.message,
    );
    
    notifyListeners();
    return result;
  }
  
  // Validação
  bool get isValid => 
    _email.isNotEmpty && 
    _password.length >= 6;
  
  @override
  void dispose() {
    login.dispose();
    super.dispose();
  }
}
```

### View Consumindo ViewModel

```dart
// ui/features/auth/widgets/login_screen.dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LoginViewModel(
        authRepository: ctx.read(),
      ),
      child: const _LoginContent(),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();
  
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: viewModel.setEmail,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: viewModel.setPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            
            // Usando ListenableBuilder para o Command
            ListenableBuilder(
              listenable: viewModel.login,
              builder: (context, _) {
                if (viewModel.login.running) {
                  return const CircularProgressIndicator();
                }
                
                return ElevatedButton(
                  onPressed: viewModel.isValid
                      ? () => viewModel.login.execute(
                          LoginCredentials(
                            email: viewModel.email,
                            password: viewModel.password,
                          ),
                        )
                      : null,
                  child: const Text('Entrar'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## ⚡ Padrão Command

O padrão Command encapsula ações assíncronas, gerenciando automaticamente estados de loading e erro.

### Implementação Base

```dart
// core/ui/commands/command.dart

/// Command sem parâmetros
class Command0<T> extends ChangeNotifier {
  Command0(this._action);
  
  final Future<Result<T>> Function() _action;
  
  bool _running = false;
  bool get running => _running;
  
  Result<T>? _result;
  Result<T>? get result => _result;
  
  bool get completed => _result != null;
  bool get hasError => _result?.isFailure ?? false;
  T? get data => _result is Success<T> ? (_result as Success<T>).data : null;
  
  Future<void> execute() async {
    if (_running) return;
    
    _running = true;
    _result = null;
    notifyListeners();
    
    try {
      _result = await _action();
    } catch (e) {
      _result = Result.failure(Failure(message: e.toString()));
    }
    
    _running = false;
    notifyListeners();
  }
  
  void clear() {
    _result = null;
    notifyListeners();
  }
}

/// Command com 1 parâmetro
class Command1<T, A> extends ChangeNotifier {
  Command1(this._action);
  
  final Future<Result<T>> Function(A) _action;
  
  bool _running = false;
  bool get running => _running;
  
  Result<T>? _result;
  Result<T>? get result => _result;
  
  Future<void> execute(A argument) async {
    if (_running) return;
    
    _running = true;
    _result = null;
    notifyListeners();
    
    try {
      _result = await _action(argument);
    } catch (e) {
      _result = Result.failure(Failure(message: e.toString()));
    }
    
    _running = false;
    notifyListeners();
  }
}
```

### Uso na View

```dart
// Rebuild apenas quando o command muda
ListenableBuilder(
  listenable: viewModel.saveCommand,
  builder: (context, _) {
    if (viewModel.saveCommand.running) {
      return const CircularProgressIndicator();
    }
    
    if (viewModel.saveCommand.hasError) {
      return Text('Erro: ${viewModel.saveCommand.result}');
    }
    
    return ElevatedButton(
      onPressed: () => viewModel.saveCommand.execute(),
      child: const Text('Salvar'),
    );
  },
)
```

## 🔄 ListenableBuilder vs Consumer

### ListenableBuilder (Recomendado)

Mais granular e eficiente para rebuilds específicos:

```dart
// Rebuild apenas quando o ViewModel muda
ListenableBuilder(
  listenable: viewModel,
  builder: (context, child) {
    return Text('Count: ${viewModel.count}');
  },
)

// Rebuild apenas quando um Command específico muda
ListenableBuilder(
  listenable: viewModel.loadCommand,
  builder: (context, _) {
    if (viewModel.loadCommand.running) {
      return const CircularProgressIndicator();
    }
    return const SizedBox.shrink();
  },
)

// Múltiplos listenables
ListenableBuilder(
  listenable: Listenable.merge([
    viewModel.loadCommand,
    viewModel.saveCommand,
  ]),
  builder: (context, _) {
    // ...
  },
)
```

### Consumer (Provider)

Para injeção + listening combinados:

```dart
// Injeta E escuta mudanças
Consumer<HomeViewModel>(
  builder: (context, viewModel, child) {
    return Text('Items: ${viewModel.items.length}');
  },
)

// Apenas leitura (sem rebuild)
final viewModel = context.read<HomeViewModel>();
viewModel.doSomething();

// Escuta mudanças
final viewModel = context.watch<HomeViewModel>();
```

## 📦 Injeção de Dependência

### Setup Global

```dart
// main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        // Services (singleton)
        Provider(create: (_) => ApiService()),
        Provider(create: (_) => StorageService()),
        
        // Repositories (singleton)
        Provider<UserRepository>(
          create: (ctx) => UserRepositoryImpl(
            apiService: ctx.read(),
            storageService: ctx.read(),
          ),
        ),
        Provider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            apiService: ctx.read(),
          ),
        ),
        
        // ViewModels Globais (quando necessário)
        ChangeNotifierProvider(
          create: (ctx) => AuthViewModel(
            authRepository: ctx.read(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### ViewModel por Tela

```dart
// Cada tela cria sua própria ViewModel
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ProfileViewModel(
        userRepository: ctx.read(),
      ),
      child: const _ProfileContent(),
    );
  }
}
```

## 🎯 Quando Usar Cada Abordagem

### setState (Estado Efêmero)

```dart
// ✅ Correto para estado local simples
class ExpandableCard extends StatefulWidget {
  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        height: _isExpanded ? 200 : 100,
        // ...
      ),
    );
  }
}
```

**Use para:**
- ✅ Animações locais
- ✅ Toggle de visibilidade
- ✅ Estado de formulário simples
- ✅ Tab/Page index

### ViewModel (Estado de Feature)

**Use para:**
- ✅ Estado de tela/feature
- ✅ Chamadas de API
- ✅ Lógica de negócios
- ✅ Estado que precisa sobreviver a rebuilds

### ViewModel Global (Estado do App)

**Use para:**
- ✅ Autenticação/Usuário logado
- ✅ Tema/Preferências
- ✅ Carrinho de compras
- ✅ Notificações globais

## 🧪 Testando ViewModels

```dart
void main() {
  late LoginViewModel viewModel;
  late MockAuthRepository mockAuthRepository;
  
  setUp(() {
    mockAuthRepository = MockAuthRepository();
    viewModel = LoginViewModel(authRepository: mockAuthRepository);
  });
  
  tearDown(() {
    viewModel.dispose();
  });
  
  group('LoginViewModel', () {
    test('initial state is correct', () {
      expect(viewModel.email, isEmpty);
      expect(viewModel.password, isEmpty);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isValid, isFalse);
    });
    
    test('setEmail updates email', () {
      viewModel.setEmail('test@test.com');
      expect(viewModel.email, 'test@test.com');
    });
    
    test('isValid returns true when form is valid', () {
      viewModel.setEmail('test@test.com');
      viewModel.setPassword('123456');
      expect(viewModel.isValid, isTrue);
    });
    
    test('login command calls repository', () async {
      when(() => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => Result.success(testUser));
      
      viewModel.setEmail('test@test.com');
      viewModel.setPassword('123456');
      
      await viewModel.login.execute(
        LoginCredentials(
          email: viewModel.email,
          password: viewModel.password,
        ),
      );
      
      verify(() => mockAuthRepository.login(
        email: 'test@test.com',
        password: '123456',
      )).called(1);
      
      expect(viewModel.login.hasError, isFalse);
    });
    
    test('login command sets error on failure', () async {
      when(() => mockAuthRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => Result.failure(
        Failure(message: 'Credenciais inválidas'),
      ));
      
      await viewModel.login.execute(
        LoginCredentials(email: 'test@test.com', password: 'wrong'),
      );
      
      expect(viewModel.errorMessage, 'Credenciais inválidas');
    });
  });
}
```

## 📋 Checklist

- [ ] ViewModel estende `ChangeNotifier`
- [ ] Dependências injetadas via construtor
- [ ] Estado exposto via getters imutáveis
- [ ] Commands para ações assíncronas
- [ ] `dispose()` implementado corretamente
- [ ] Views usam `ListenableBuilder` ou `Consumer`
- [ ] Testes unitários para ViewModels

## 📚 Recursos

- [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture)
- [ChangeNotifier Documentation](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)
- [Provider Package](https://pub.dev/packages/provider)
- [Command Pattern](https://docs.flutter.dev/app-architecture/guide#command-pattern)

---

*Baseado na documentação oficial de Arquitetura Flutter (2025).*
