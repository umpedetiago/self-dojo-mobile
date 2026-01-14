# Changelog - Self Dojo Mobile

Documentação das mudanças implementadas e planejamento dos próximos passos.

---

## 📅 Histórico de Commits

### [c915fbd] - Implement Academy and Student Management Features
**Data:** Recente

**Mudanças:**
- Implementação do gerenciamento de academias e alunos
- Criação de ViewModels para academias e estudantes
- Telas de gerenciamento de alunos

---

### [67825f5] - Add ProfileService and Update Profile Management
**Data:** Anterior

**Mudanças:**
- Adição do `ProfileService` para centralizar operações de perfil
- Atualização do gerenciamento de perfis

---

### [0a8639d] - Integrate Supabase for Backend Services
**Data:** Anterior

**Mudanças Principais:**
- **Substituição do Firebase Firestore** pelo Supabase (PostgreSQL)
- Implementação de novos repositórios:
  - `ProfileRepositorySupabase`
  - `AcademyRepositorySupabase`
  - `AcademySearchRepositorySupabase`
  - `StudentsRepositorySupabase`
- **Registro de usuário** atualizado com seleção de role e tipo de arte marcial
- Adição da configuração e setup do Supabase (`supabase_config.dart`)
- Remoção dos serviços legados do Firestore
- Ajuste dos modelos de dados para o novo backend

---

### [e19e496] - Initialize Flutter Project Structure
**Data:** Inicial

**Mudanças:**
- Estrutura inicial do projeto Flutter
- Configuração do Firebase (Auth ainda em uso)
- Setup do Android e iOS
- Implementação da arquitetura MVVM
- Componentes iniciais de UI (autenticação e academias)

---

## ✅ Funcionalidades Implementadas

### 1. Autenticação (Firebase Auth)
- [x] Login com email/senha
- [x] Registro de novo usuário
- [x] Seleção de role durante registro (student/owner)
- [x] Seleção de arte marcial durante registro
- [x] Splash screen com verificação de auth

### 2. Perfil de Usuário
- [x] `UserProfile` model com campos completos
- [x] `ProfileRepository` interface
- [x] `ProfileRepositorySupabase` implementação
- [x] `ProfileService` para operações de perfil
- [x] Tela de edição de perfil (`edit_profile_screen.dart`)
- [x] Upload de foto de perfil (Supabase Storage)

### 3. Sistema de Academias
- [x] `Academy` model completo
- [x] `AcademyRepository` interface
- [x] `AcademyRepositorySupabase` implementação
- [x] Tela de criação de academia
- [x] Tela de gerenciamento de academia
- [x] Tela de modalidades
- [x] Tela de configuração de graduações

### 4. Busca de Academias
- [x] `AcademySearchRepository` interface
- [x] `AcademySearchRepositorySupabase` implementação
- [x] Tela de busca de academias
- [x] `SearchAcademyViewModel`

### 5. Gerenciamento de Alunos
- [x] `StudentsRepository` interface
- [x] `StudentsRepositorySupabase` implementação
- [x] `StudentsViewModel`
- [x] Tela de lista de alunos
- [x] Tela de detalhes do aluno

### 6. Solicitações de Entrada
- [x] `RequestsViewModel`
- [x] Tela de solicitações pendentes

### 7. Supabase Backend
- [x] Schema PostgreSQL completo (`supabase/schema.sql`)
- [x] Tabelas: users, academies, academy_modalities, belt_configs
- [x] Tabelas: academy_members, modality_teachers, student_modalities
- [x] Tabelas: graduation_history, student_plans, check_ins
- [x] Views: v_academy_members_full, v_student_modalities_full
- [x] Functions: update_updated_at, increment_student_classes, promote_student
- [x] Row Level Security (RLS) básico
- [x] `SupabaseService` para operações de banco

### 8. Sistema de Graduação
- [x] `Belt` model com faixas de BJJ
- [x] `MartialArt` model com tipos de artes marciais
- [x] `StudentModality` para matrículas em modalidades
- [x] `GraduationHistory` para histórico de promoções

### 9. Roles (Papéis)
- [x] Enum `UserRole` com: student, instructor, teacher, modalityMaster, owner
- [x] Documentação completa do sistema de roles (`ROLES_SYSTEM.md`)

---

## 🔧 Mudança Recente (Não Commitada)

### ProfileRepositorySupabase - Fix Upload de Imagem

**Arquivo:** `lib/data/repositories/profile_repository_supabase.dart`

**Problema:** O método `uploadProfileImage` usava `Result.fold()` de forma incorreta tentando retornar um valor assíncrono dentro do callback.

**Antes:**
```dart
return result.fold(
  onSuccess: (url) async {
    final existing = await _supabaseService.getUserByFirebaseUid(userId);
    if (existing != null) {
      await _supabaseService.updateUser(existing['id'], {'photo_url': url});
    }
    return Result.success(url);
  },
  onFailure: (failure) => Result.failure(failure),
);
```

**Depois:**
```dart
if (result.isFailure) {
  final failure = result as Failure<String>;
  return Failure<String>(message: failure.message, code: failure.code);
}

final url = (result as Success<String>).data;

// Atualiza o perfil com a nova URL
final existing = await _supabaseService.getUserByFirebaseUid(userId);
if (existing != null) {
  await _supabaseService.updateUser(existing['id'], {'photo_url': url});
}

return Result.success(url);
```

**Motivo:** O padrão `fold` não permite operações assíncronas dentro dos callbacks. A solução usa verificação explícita de `isFailure` e casting seguro.

---

## 🚧 Funcionalidades Pendentes

### Fase 1 - Fundação (Em Progresso)
- [ ] Validar fluxo completo de registro → seleção de role → criação de perfil
- [ ] Testar integração completa com Supabase
- [ ] Implementar tratamento de erros mais robusto

### Fase 2 - Owner & Academia
- [ ] Fluxo de assinatura/trial do app
- [ ] Dashboard do owner
- [ ] Estatísticas da academia

### Fase 3 - Mestre de Modalidade
- [ ] Fluxo de indicação de mestre pelo owner
- [ ] Configuração de graduações por modalidade
- [ ] Relatórios por modalidade

### Fase 4 - Aluno & Vinculação
- [ ] Fluxo completo de solicitação → aprovação
- [ ] Notificações de aprovação/rejeição
- [ ] Visualização de informações da academia

### Fase 5 - Financeiro (Owner)
- [ ] Configuração de planos de mensalidade
- [ ] Dashboard financeiro
- [ ] Registro de pagamentos

### Fase 6 - Check-in & Frequência
- [ ] Sistema de check-in de presença
- [ ] Relatórios de frequência
- [ ] Histórico de aulas

### Fase 7 - Promoções
- [ ] Fluxo de promoção de alunos
- [ ] Verificação de requisitos
- [ ] Histórico de graduações

---

## 🏗️ Arquitetura Implementada

```
lib/
├── core/
│   ├── config/          ✅ app_router, supabase_config
│   ├── theme/           ✅ app_colors, app_text_styles, app_theme
│   ├── ui/commands/     ✅ Command pattern
│   └── utils/           ✅ Result pattern
├── data/
│   ├── repositories/    ✅ 8 repositórios (4 interfaces + 4 implementações)
│   └── services/        ✅ firebase_auth, supabase, profile services
├── domain/models/
│   ├── academy/         ✅ 8 modelos de academia
│   ├── martial_arts/    ✅ belt, martial_art
│   └── user_profile     ✅ perfil completo
└── ui/features/
    ├── academy/         ✅ 8 widgets + 4 viewmodels
    ├── auth/            ✅ 3 widgets + 3 viewmodels
    ├── home/            ✅ 4 widgets
    ├── profile/         ✅ 1 widget + 1 viewmodel
    └── splash/          ✅ 1 widget
```

---

## 📊 Métricas do Projeto

| Categoria | Quantidade |
|-----------|------------|
| Repositories | 8 (4 interfaces + 4 Supabase) |
| Services | 3 |
| ViewModels | 8 |
| Telas/Widgets | 17+ |
| Modelos de Domínio | 12+ |
| Tabelas no DB | 10 |
| Views SQL | 2 |
| Functions SQL | 3 |

---

## 🎯 Próximos Passos Recomendados

### Imediato (Próxima Sprint)
1. **Commitar** a correção do `uploadProfileImage`
2. **Testar** fluxo completo: registro → login → criação de academia
3. **Revisar** RLS policies do Supabase para garantir segurança
4. **Implementar** tratamento de erros com mensagens user-friendly

### Curto Prazo
1. Completar fluxo de vinculação aluno → academia
2. Implementar notificações de aprovação
3. Dashboard básico para owner

### Médio Prazo
1. Sistema de check-in
2. Fluxo de promoções
3. Relatórios básicos

---

## 📝 Notas de Desenvolvimento

### Padrões Utilizados
- **Arquitetura:** MVVM com Clean Architecture
- **State Management:** ChangeNotifier + Provider
- **Error Handling:** Result Pattern (Success/Failure)
- **Async Actions:** Command Pattern
- **Backend:** Supabase (PostgreSQL + Storage)
- **Auth:** Firebase Authentication

### Convenções
- ViewModels em `ui/features/{feature}/view_models/`
- Widgets em `ui/features/{feature}/widgets/`
- Repositórios com interface + implementação Supabase
- Modelos imutáveis no domínio
- Tudo em português nos comentários, inglês no código

---

*Última atualização: Janeiro 2026*


