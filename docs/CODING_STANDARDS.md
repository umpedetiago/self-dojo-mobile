# Padrões de Código

Guia de convenções e boas práticas para o desenvolvimento do Self Dojo Mobile.

## 📏 Formatação

### Configuração do Analysis Options

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    - always_declare_return_types
    - always_use_package_imports
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - avoid_type_to_string
    - avoid_types_as_parameter_names
    - avoid_web_libraries_in_flutter
    - cancel_subscriptions
    - close_sinks
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - require_trailing_commas
    - sort_constructors_first
    - sort_unnamed_constructors_first
    - use_key_in_widget_constructors
```

### Limite de Linha

Máximo de **80 caracteres** por linha.

### Trailing Commas

**Sempre** use trailing commas em listas e argumentos multi-linha:

```dart
// ✅ Correto
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Item 1'),
        Text('Item 2'),
        Text('Item 3'), // <- trailing comma
      ],
    ),
  );
}

// ❌ Incorreto
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Item 1'),
        Text('Item 2'),
        Text('Item 3')  // <- sem trailing comma
      ]
    )
  );
}
```

## 📛 Nomenclatura

### Arquivos e Pastas

- Use `snake_case` para arquivos e pastas
- Sufixos por tipo de arquivo:

| Tipo | Sufixo | Exemplo |
|------|--------|---------|
| Screen (View) | `_screen.dart` | `home_screen.dart` |
| ViewModel | `_viewmodel.dart` | `home_viewmodel.dart` |
| Widget | `_widget.dart` | `custom_button_widget.dart` |
| API Model | `_api_model.dart` | `user_api_model.dart` |
| Domain Model | `.dart` | `user.dart` |
| Repository | `_repository.dart` | `user_repository.dart` |
| Service | `_service.dart` | `api_service.dart` |
| Command | `_command.dart` | `load_command.dart` |
| Extension | `_extension.dart` | `string_extension.dart` |

### Classes e Tipos

```dart
// Classes: PascalCase
class UserProfile {}
class AuthenticationBloc {}

// Enums: PascalCase com valores camelCase
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

// Typedefs: PascalCase
typedef JsonMap = Map<String, dynamic>;
typedef VoidCallback = void Function();
```

### Variáveis e Funções

```dart
// Variáveis: camelCase
final userName = 'John';
String? userEmail;

// Constantes: lowerCamelCase (não SCREAMING_CASE)
const defaultTimeout = Duration(seconds: 30);
const maxRetries = 3;

// Constantes privadas no topo do arquivo
const _animationDuration = Duration(milliseconds: 300);

// Funções: camelCase
void fetchUserData() {}
Future<User> getUserById(String id) async {}
```

### Variáveis Privadas

```dart
// Prefixo underscore para privado
class MyClass {
  final String _privateField;
  
  void _privateMethod() {}
}
```

## 🏗️ Estrutura de Classes

### Ordem dos Membros

```dart
class ExampleWidget extends StatefulWidget {
  // 1. Constantes estáticas
  static const defaultPadding = 16.0;
  
  // 2. Campos estáticos
  static int instanceCount = 0;
  
  // 3. Campos finais públicos
  final String title;
  final VoidCallback? onTap;
  
  // 4. Campos finais privados
  final String _internalId;
  
  // 5. Construtor (primeiro unnamed, depois named)
  const ExampleWidget({
    super.key,
    required this.title,
    this.onTap,
  }) : _internalId = 'id';
  
  // 6. Factory constructors
  factory ExampleWidget.empty() => const ExampleWidget(title: '');
  
  // 7. Métodos estáticos
  static void resetCount() => instanceCount = 0;
  
  // 8. Override de State
  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  // 1. Campos
  late final TextEditingController _controller;
  bool _isLoading = false;
  
  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  // 4. Métodos privados auxiliares
  void _handleTap() {}
}
```

## 🎨 Widgets

### Preferências

```dart
// ✅ Prefira const constructors
const SizedBox(height: 16);
const EdgeInsets.all(8);

// ✅ Prefira widgets específicos
const SizedBox(height: 16);  // ao invés de Container(height: 16)
const ColoredBox(color: Colors.red);  // ao invés de Container(color: ...)

// ✅ Use const para widgets que não mudam
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});  // <- const constructor
  
  @override
  Widget build(BuildContext context) {
    return const Text('Hello');  // <- const widget
  }
}
```

### Keys

```dart
// Use keys em listas
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),  // <- importante!
      title: Text(items[index].name),
    );
  },
);
```

### Extração de Widgets

```dart
// ✅ Extraia widgets complexos para classes separadas
class UserCard extends StatelessWidget {
  final User user;
  
  const UserCard({super.key, required this.user});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _buildAvatar(),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
      ),
    );
  }
  
  Widget _buildAvatar() => CircleAvatar(
    backgroundImage: NetworkImage(user.avatarUrl),
  );
  
  Widget _buildTitle() => Text(user.name);
  
  Widget _buildSubtitle() => Text(user.email);
}

// ❌ Evite métodos que retornam widgets em StatefulWidget
// (perda de performance por rebuilds desnecessários)
```

## 🔄 Async/Await

```dart
// ✅ Sempre trate erros
Future<void> fetchData() async {
  try {
    final data = await api.getData();
    // ...
  } on ApiException catch (e) {
    // Erro específico
  } catch (e, stackTrace) {
    // Erro genérico - sempre logue o stackTrace
    logger.error('Erro ao buscar dados', e, stackTrace);
  }
}

// ✅ Use async/await ao invés de .then()
// Correto
final user = await getUser();
final posts = await getPosts(user.id);

// Incorreto
getUser().then((user) {
  getPosts(user.id).then((posts) {
    // ...
  });
});
```

## 📝 Documentação

### Comentários de Documentação

```dart
/// Representa um usuário no sistema.
/// 
/// Um [User] contém informações básicas como [name] e [email],
/// além de seu identificador único [id].
/// 
/// Exemplo:
/// ```dart
/// final user = User(
///   id: '123',
///   name: 'John Doe',
///   email: 'john@example.com',
/// );
/// ```
class User {
  /// Identificador único do usuário.
  final String id;
  
  /// Nome completo do usuário.
  final String name;
  
  /// Email do usuário.
  /// 
  /// Deve ser um email válido e único no sistema.
  final String email;
  
  /// Cria uma nova instância de [User].
  /// 
  /// Todos os parâmetros são obrigatórios.
  const User({
    required this.id,
    required this.name,
    required this.email,
  });
}
```

### TODOs

```dart
// TODO(nome): Descrição da tarefa pendente
// FIXME(nome): Descrição do bug a ser corrigido
// HACK(nome): Explicação do workaround temporário
```

## ✅ Checklist de Code Review

- [ ] Código formatado (`dart format .`)
- [ ] Sem warnings do analyzer (`dart analyze`)
- [ ] Testes passando (`flutter test`)
- [ ] Documentação atualizada
- [ ] Nomenclatura consistente
- [ ] Sem código comentado
- [ ] Sem prints (use logger)
- [ ] Tratamento de erros adequado
- [ ] Keys em listas
- [ ] Const constructors onde possível

## 🛠️ Comandos Úteis

```bash
# Formatar código
dart format .

# Analisar código
dart analyze

# Corrigir problemas automaticamente
dart fix --apply

# Gerar arquivos (build_runner)
dart run build_runner build --delete-conflicting-outputs
```

---

*Última atualização: Janeiro 2026*

