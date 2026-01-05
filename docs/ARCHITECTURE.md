# Arquitetura do Projeto

Este documento descreve os padrões de arquitetura e diretrizes de desenvolvimento adotados neste projeto. A arquitetura segue as recomendações oficiais do time do Flutter, baseada em **Separation of Concerns (Separação de Preocupações)**, **MVVM (Model-View-ViewModel)** e uma **Camada de Dados** robusta.

## 🏗️ Visão Geral

O aplicativo é dividido em três camadas principais:

```
┌─────────────────────────────────────────────────────────┐
│                    CAMADA DE UI                         │
│              (Views + ViewModels)                       │
├─────────────────────────────────────────────────────────┤
│              CAMADA DE DOMÍNIO (Opcional)               │
│                    (Use Cases)                          │
├─────────────────────────────────────────────────────────┤
│                  CAMADA DE DADOS                        │
│           (Repositories + Services)                     │
└─────────────────────────────────────────────────────────┘
```

| Camada | Responsabilidade |
|--------|------------------|
| **UI Layer** | Exibir dados e lidar com interação do usuário (Views + ViewModels) |
| **Data Layer** | Lógica de negócios, acesso a APIs e persistência (Repositories + Services) |
| **Domain Layer** | Lógicas complexas reutilizáveis - opcional (Use Cases) |

## 📂 Estrutura de Pastas

Utilizamos uma estrutura **híbrida**: Feature-based para UI e Type-based para dados/domínio.

```
lib/
├── core/                       # Widgets e utilitários compartilhados
│   ├── config/
│   │   ├── app_config.dart
│   │   └── env_config.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── api_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── utils/
│   │   ├── extensions/
│   │   ├── helpers/
│   │   └── validators.dart
│   └── ui/
│       ├── widgets/            # Widgets reutilizáveis globais
│       └── commands/           # Command pattern base classes
│
├── data/                       # Camada de Dados (Type-based)
│   ├── models/                 # API Models (JSON serialization)
│   │   └── user_api_model.dart
│   ├── repositories/           # Implementações dos repositórios
│   │   └── user_repository.dart
│   └── services/               # Classes de acesso à API/Plugins
│       ├── api/
│       │   └── api_client.dart
│       └── local/
│           └── storage_service.dart
│
├── domain/                     # Camada de Domínio (Type-based)
│   ├── models/                 # Domain Models (usados pela UI)
│   │   └── user.dart
│   └── usecases/               # Use Cases (opcional)
│       └── authenticate_user.dart
│
├── ui/                         # Camada de UI (Feature-based)
│   ├── common/                 # Widgets compartilhados entre features
│   │   └── widgets/
│   └── features/
│       ├── auth/
│       │   ├── view_models/
│       │   │   └── login_viewmodel.dart
│       │   └── widgets/
│       │       ├── login_screen.dart
│       │       └── login_form.dart
│       ├── home/
│       │   ├── view_models/
│       │   │   └── home_viewmodel.dart
│       │   └── widgets/
│       │       └── home_screen.dart
│       └── profile/
│           ├── view_models/
│           │   └── profile_viewmodel.dart
│           └── widgets/
│               └── profile_screen.dart
│
├── l10n/                       # Internacionalização
│   ├── app_en.arb
│   └── app_pt.arb
│
└── main.dart
```

## 🎨 Camada de UI (Interface do Usuário)

A UI segue o padrão **MVVM (Model-View-ViewModel)**.

### Views (Widgets)

**Responsabilidade:** Renderizar a UI baseada no estado fornecido pela ViewModel.

**Regras:**
- ✅ Devem ser "burras" (sem lógica de negócios)
- ✅ Ouvem mudanças na ViewModel usando `ListenableBuilder`
- ✅ Passam eventos do usuário para a ViewModel via métodos ou Commands
- ❌ **NÃO** devem acessar Repositories ou Services diretamente

```dart
// ui/features/home/widgets/home_screen.dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.viewModel});
  
  final HomeViewModel viewModel;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (viewModel.error != null) {
            return Center(child: Text('Erro: ${viewModel.error}'));
          }
          
          return ListView.builder(
            itemCount: viewModel.items.length,
            itemBuilder: (context, index) {
              final item = viewModel.items[index];
              return ListTile(
                title: Text(item.name),
                onTap: () => viewModel.selectItem(item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => viewModel.loadItems.execute(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

### ViewModels

**Responsabilidade:** Gerenciar o estado da UI e mediar a comunicação com a camada de dados.

**Regras:**
- ✅ Uma ViewModel por View (relação 1:1 para features/telas)
- ✅ Estendem `ChangeNotifier` para notificar a View sobre mudanças
- ✅ Expõem dados prontos para consumo da UI (getters imutáveis)
- ✅ Utilizam o padrão **Command** para ações assíncronas
- ✅ Recebem Repositories via **injeção de dependência** no construtor

```dart
// ui/features/home/view_models/home_viewmodel.dart
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required ItemRepository itemRepository})
      : _itemRepository = itemRepository {
    // Inicializa o Command
    loadItems = Command0(_loadItems)..execute();
  }
  
  final ItemRepository _itemRepository;
  
  // Estado
  List<Item> _items = [];
  List<Item> get items => List.unmodifiable(_items);
  
  Item? _selectedItem;
  Item? get selectedItem => _selectedItem;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  // Commands
  late final Command0 loadItems;
  
  // Actions
  Future<Result<void>> _loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final result = await _itemRepository.getItems();
    
    result.fold(
      onSuccess: (data) {
        _items = data;
        _isLoading = false;
      },
      onFailure: (error) {
        _error = error.message;
        _isLoading = false;
      },
    );
    
    notifyListeners();
    return result;
  }
  
  void selectItem(Item item) {
    _selectedItem = item;
    notifyListeners();
  }
  
  @override
  void dispose() {
    loadItems.dispose();
    super.dispose();
  }
}
```

### Padrão Command

O padrão Command encapsula ações assíncronas com estados de loading/error:

```dart
// core/ui/commands/command.dart
class Command0<T> extends ChangeNotifier {
  Command0(this._action);
  
  final Future<Result<T>> Function() _action;
  
  bool _running = false;
  bool get running => _running;
  
  Result<T>? _result;
  Result<T>? get result => _result;
  
  bool get completed => _result != null;
  bool get error => _result?.isFailure ?? false;
  
  Future<void> execute() async {
    if (_running) return;
    
    _running = true;
    _result = null;
    notifyListeners();
    
    _result = await _action();
    
    _running = false;
    notifyListeners();
  }
  
  void dispose() {
    // Cleanup if needed
  }
}

// Command com parâmetro
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
    
    _result = await _action(argument);
    
    _running = false;
    notifyListeners();
  }
}
```

## 💾 Camada de Dados (Data Layer)

### Repositories

**Responsabilidade:** Fonte única da verdade (SSOT) para os dados do app.

**Regras:**
- ✅ Gerenciam a decisão de onde buscar dados (cache vs API)
- ✅ Tratam exceções e transformam API Models em Domain Models
- ✅ São agnósticos à UI (não sabem que a ViewModel existe)
- ✅ Definem contratos abstratos para permitir Mocking
- ✅ Retornam `Result<T>` ao invés de lançar exceções

```dart
// data/repositories/user_repository.dart

// Contrato abstrato
abstract class UserRepository {
  Future<Result<User>> getUser(String id);
  Future<Result<void>> updateUser(User user);
  Future<Result<List<User>>> getUsers();
}

// Implementação
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;
  
  final ApiService _apiService;
  final StorageService _storageService;
  
  @override
  Future<Result<User>> getUser(String id) async {
    try {
      // Tenta cache primeiro
      final cached = await _storageService.getCachedUser(id);
      if (cached != null) {
        return Result.success(cached.toDomain());
      }
      
      // Busca da API
      final response = await _apiService.get('/users/$id');
      final apiModel = UserApiModel.fromJson(response);
      
      // Salva no cache
      await _storageService.cacheUser(apiModel);
      
      // Retorna domain model
      return Result.success(apiModel.toDomain());
    } on ApiException catch (e) {
      return Result.failure(Failure(message: e.message, code: e.code));
    } catch (e) {
      return Result.failure(Failure(message: 'Erro inesperado'));
    }
  }
  
  @override
  Future<Result<void>> updateUser(User user) async {
    try {
      await _apiService.put('/users/${user.id}', body: user.toJson());
      return Result.success(null);
    } on ApiException catch (e) {
      return Result.failure(Failure(message: e.message));
    }
  }
}
```

### Services

**Responsabilidade:** Encapsular chamadas externas (HTTP, Banco de Dados, Sensores).

**Regras:**
- ✅ São **stateless** (não guardam estado)
- ✅ Retornam dados brutos ou objetos de resposta
- ✅ Um serviço pode ser usado por múltiplos repositories

```dart
// data/services/api/api_service.dart
class ApiService {
  ApiService({required Dio dio}) : _dio = dio;
  
  final Dio _dio;
  
  Future<Map<String, dynamic>> get(String path) async {
    final response = await _dio.get(path);
    return response.data;
  }
  
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post(path, data: body);
    return response.data;
  }
  
  Future<void> put(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    await _dio.put(path, data: body);
  }
}
```

## 🔄 Fluxo de Dados (Unidirecional)

```
┌─────────────────────────────────────────────────────────┐
│  1. UI: Usuário interage (clica em "Salvar")            │
│     View chama método na ViewModel                      │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  2. ViewModel: Processa a lógica                        │
│     Chama o Repository                                  │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  3. Repository: Busca/Atualiza dados                    │
│     Usa Services (API, Cache)                           │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  4. ViewModel: Recebe resultado                         │
│     Atualiza estado e chama notifyListeners()           │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  5. UI: Reconstrói baseada no novo estado               │
│     ListenableBuilder detecta mudança                   │
└─────────────────────────────────────────────────────────┘
```

## ✅ Modelagem de Dados

### Result Pattern

```dart
// core/utils/result.dart
sealed class Result<T> {
  const Result();
  
  factory Result.success(T data) = Success<T>;
  factory Result.failure(Failure failure) = Failure<T>;
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  });
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
  
  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) => onSuccess(data);
}

class Failure<T> extends Result<T> {
  const Failure({required this.message, this.code});
  final String message;
  final String? code;
  
  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) => onFailure(this as Failure);
}
```

### Separação de Models

```dart
// data/models/user_api_model.dart (API Model)
@JsonSerializable()
class UserApiModel {
  final String id;
  final String full_name;  // snake_case da API
  final String email_address;
  final String? avatar_url;
  
  const UserApiModel({
    required this.id,
    required this.full_name,
    required this.email_address,
    this.avatar_url,
  });
  
  factory UserApiModel.fromJson(Map<String, dynamic> json) =>
      _$UserApiModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserApiModelToJson(this);
  
  // Converte para Domain Model
  User toDomain() => User(
    id: id,
    name: full_name,
    email: email_address,
    avatarUrl: avatar_url,
  );
}

// domain/models/user.dart (Domain Model - usado pela UI)
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
  }) = _User;
}
```

## 🔌 Injeção de Dependência

Utilizamos o pacote `provider` para injetar dependências:

```dart
// main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => Dio()..options.baseUrl = apiBaseUrl),
        Provider(create: (ctx) => ApiService(dio: ctx.read())),
        Provider(create: (_) => StorageService()),
        
        // Repositories
        Provider<UserRepository>(
          create: (ctx) => UserRepositoryImpl(
            apiService: ctx.read(),
            storageService: ctx.read(),
          ),
        ),
        
        // ViewModels (quando necessário global)
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

// Na tela específica
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HomeViewModel(
        itemRepository: ctx.read(),
      ),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, _) {
          return HomeContent(viewModel: viewModel);
        },
      ),
    );
  }
}
```

## 📋 Checklist de Arquitetura

### Views
- [ ] Sem lógica de negócios
- [ ] Usa `ListenableBuilder` para reagir a mudanças
- [ ] Não acessa Repository/Service diretamente

### ViewModels
- [ ] Estende `ChangeNotifier`
- [ ] Recebe dependências via construtor
- [ ] Usa Commands para ações async
- [ ] Expõe getters imutáveis

### Repositories
- [ ] Retorna `Result<T>` (não lança exceções)
- [ ] Transforma API Model em Domain Model
- [ ] Gerencia cache quando apropriado
- [ ] Define interface abstrata

### Models
- [ ] API Models com `@JsonSerializable`
- [ ] Domain Models imutáveis (usar `freezed`)
- [ ] Método `toDomain()` nos API Models

## 📚 Referências

- [Flutter Architecture Guide (2025)](https://docs.flutter.dev/app-architecture)
- [MVVM Pattern](https://docs.flutter.dev/app-architecture/guide)
- [Command Pattern](https://docs.flutter.dev/app-architecture/guide#command-pattern)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

*Baseado na documentação oficial de Arquitetura Flutter (2025).*
