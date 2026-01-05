# Self Dojo Mobile - Documentação

Bem-vindo à documentação do projeto **Self Dojo Mobile**. Este guia contém todas as informações necessárias para desenvolver, manter e publicar o aplicativo.

## 📚 Índice da Documentação

| Documento | Descrição |
|-----------|-----------|
| [Getting Started](./GETTING_STARTED.md) | Configuração inicial do ambiente de desenvolvimento |
| [Arquitetura](./ARCHITECTURE.md) | Estrutura MVVM e organização do projeto |
| [Padrões de Código](./CODING_STANDARDS.md) | Convenções e boas práticas de código |
| [Gerenciamento de Estado](./STATE_MANAGEMENT.md) | ChangeNotifier, Commands e ViewModels |
| [Navegação](./NAVIGATION.md) | Sistema de rotas e navegação |
| [Testes](./TESTING.md) | Guia completo de testes |
| [Deployment](./DEPLOYMENT.md) | Publicação nas lojas (iOS/Android) |
| [CI/CD](./CI_CD.md) | Integração e entrega contínua |

## 🚀 Início Rápido

```bash
# Clone o repositório
git clone <url-do-repositorio>

# Entre na pasta do projeto
cd self-dojo-mobile

# Instale as dependências
flutter pub get

# Execute o app em modo debug
flutter run
```

## 📱 Plataformas Suportadas

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- 🔄 Web (em desenvolvimento)

## 🛠️ Stack Tecnológica

- **Framework**: Flutter 3.x
- **Linguagem**: Dart 3.x
- **Arquitetura**: MVVM (Model-View-ViewModel)
- **Gerenciamento de Estado**: ChangeNotifier + Commands
- **Injeção de Dependência**: Provider
- **Navegação**: GoRouter
- **HTTP Client**: Dio
- **Armazenamento Local**: SharedPreferences / Hive
- **Imutabilidade**: Freezed

## 📂 Estrutura de Pastas

```
lib/
├── core/                   # Widgets e utilitários compartilhados
│   └── ui/
├── data/                   # Camada de Dados (Type-based)
│   ├── models/             # API Models (JSON serialization)
│   ├── repositories/       # Implementações dos repositórios
│   └── services/           # Classes de acesso à API/Plugins
├── domain/                 # Camada de Domínio (Type-based)
│   └── models/             # Domain Models (usados pela UI)
├── ui/                     # Camada de UI (Feature-based)
│   ├── common/             # Widgets específicos desta feature
│   └── features/
│       └── <nome_feature>/
│           ├── view_models/
│           │   └── <feature>_viewmodel.dart
│           └── widgets/
│               └── <feature>_screen.dart
└── main.dart
```

## 🏗️ Arquitetura

O projeto segue a arquitetura **MVVM** recomendada pelo time do Flutter:

| Camada | Componentes | Responsabilidade |
|--------|-------------|------------------|
| **UI** | Views + ViewModels | Exibir dados e interação |
| **Data** | Repositories + Services | Lógica de negócios e API |
| **Domain** | Models + UseCases | Entidades e regras (opcional) |

Leia mais em [ARCHITECTURE.md](./ARCHITECTURE.md).

## 👥 Equipe

| Nome | Papel | Contato |
|------|-------|---------|
| - | - | - |

## 📝 Licença

Este projeto é privado e de propriedade da VCI Nova.

---

*Última atualização: Janeiro 2026*
