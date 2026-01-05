# Guia de Arquitetura do Projeto

Este documento descreve os padrões de arquitetura e diretrizes de desenvolvimento adotados neste projeto. A arquitetura segue as recomendações oficiais do time do Flutter, baseada em **Separation of Concerns (Separação de Preocupações)**, **MVVM (Model-View-ViewModel)** e uma **Camada de Dados** robusta.

## 🏗️ Visão Geral

O aplicativo é dividido em duas camadas principais:

1.  **Camada de UI (UI Layer):** Responsável por exibir dados e lidar com a interação do usuário. Composta por *Views* e *ViewModels*.
2.  **Camada de Dados (Data Layer):** Responsável pela lógica de negócios, acesso a APIs e persistência. Composta por *Repositories* e *Services*.
3.  **Camada de Domínio (Opcional):** Para lógicas excessivamente complexas que precisam ser reutilizadas (UseCases).

### Estrutura de Pastas Recomendada

Utilizamos uma estrutura híbrida: **Feature-based** para UI e **Type-based** para a camada de dados e domínio.

```text
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

---

## 🎨 Camada de UI (Interface do Usuário)

A UI segue o padrão **MVVM**.

### 1. Views (Widgets)
*   **Responsabilidade:** Renderizar a UI baseada no estado fornecido pela ViewModel.
*   **Regras:**
    *   Devem ser "burras" (sem lógica de negócios).
    *   Ouvem mudanças na ViewModel (usando `ListenableBuilder` ou similar).
    *   Passam eventos do usuário para a ViewModel através de chamadas de método ou *Commands*.
    *   **Não** devem acessar Repositórios ou Serviços diretamente.

### 2. ViewModels
*   **Responsabilidade:** Gerenciar o estado da UI e mediar a comunicação com a camada de dados.
*   **Regras:**
    *   Uma ViewModel por View (relação 1:1 para features/telas).
    *   Estendem `ChangeNotifier` para notificar a View sobre mudanças de estado.
    *   Expõem dados prontos para consumo da UI (ex: getters imutáveis).
    *   Utilizam o padrão **Command** para ações de usuário (opcional, mas recomendado para lidar com loading/erros de forma segura).
    *   Recebem Repositórios via injeção de dependência no construtor.

---

## 💾 Camada de Dados (Data Layer)

### 1. Repositories (Repositórios)
*   **Responsabilidade:** Fonte única da verdade (SSOT) para os dados do app.
*   **Regras:**
    *   Gerenciam a decisão de onde buscar os dados (cache local vs. API remota).
    *   Tratam exceções e transformam dados brutos (API Models) em modelos de domínio limpos (Domain Models).
    *   Devem ser agnósticos à UI (não sabem que a ViewModel existe).
    *   Definem contratos abstratos para permitir *Mocking* nos testes.

### 2. Services (Serviços)
*   **Responsabilidade:** Encapsular chamadas externas (HTTP, Banco de Dados, Sensores).
*   **Regras:**
    *   São *stateless* (não guardam estado).
    *   Retornam dados brutos ou objetos de resposta (ex: `Future<Result>`).
    *   Um serviço pode ser usado por múltiplos repositórios.

---

## 🔄 Fluxo de Dados e Comunicação

O fluxo de dados deve ser **Unidirecional (Unidirectional Data Flow - UDF)**:

1.  **UI:** O usuário interage (ex: clica em "Salvar"). A View chama um método na ViewModel.
2.  **ViewModel:** Processa a lógica e chama o Repositório.
3.  **Repository:** Busca/Atualiza dados usando um Service.
4.  **ViewModel:** Recebe o resultado, atualiza o estado local e notifica a View (`notifyListeners`).
5.  **UI:** Reconstrói-se baseada no novo estado.

### Injeção de Dependência
Utilizamos o pacote `provider` (ou similar) para injetar dependências:
*   Services são injetados em Repositories.
*   Repositories são injetados em ViewModels.

---

## ✅ Modelagem de Dados

*   **Imutabilidade:** Todos os modelos de dados (Domain e UI State) devem ser imutáveis. Recomenda-se o uso do pacote `freezed`.
*   **Separação de Modelos:**
    *   **API Models:** Refletem a estrutura exata do JSON/Banco de dados (ficam em `data/models`).
    *   **Domain Models:** Refletem o que o app precisa usar (ficam em `domain/models`).

## 🧪 Testes

*   **Testes Unitários:** Para ViewModels e Repositories. Como dependências são injetadas, deve-se criar *Mocks* ou *Fakes* dos repositórios para testar a ViewModel isoladamente.
*   **Testes de Widget:** Para garantir que a View renderiza corretamente baseada no estado da ViewModel.

---
*Baseado na documentação oficial de Arquitetura Flutter (2025).*
```

### Destaques Importantes para o seu uso:

1.  **Nomes de Arquivos:** O guia sugere seguir convenções claras, como `home_viewmodel.dart`, `home_screen.dart`, `user_repository.dart`.
2.  **Padrão Command:** Note que o documento menciona o uso de `Commands` (objetos que encapsulam uma ação e seus estados de `loading`/`error`). Isso é altamente recomendado nas fontes para evitar erros de renderização assíncrona.
3.  **Result Objects:** A arquitetura sugere que Repositórios e Serviços retornem um objeto do tipo `Result` (sucesso ou falha) em vez de lançar exceções diretamente, facilitando o tratamento de erros na ViewModel.