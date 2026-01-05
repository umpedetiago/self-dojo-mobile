# Sistema de Roles (Papéis) - Self Dojo

## 1. Visão Geral

O sistema de roles permite diferentes níveis de acesso e funcionalidades baseados no tipo de conta do usuário. A hierarquia segue a estrutura tradicional das artes marciais, com separação clara entre responsabilidades administrativas/financeiras e técnicas.

---

## 2. Hierarquia de Roles

```
┌──────────────────────────────────────────────────────────────┐
│                     MESTRE PRINCIPAL                          │
│            (Dono/Contratante da Academia)                     │
│   💰 Responsável financeiro pelo app e academia               │
│   🏢 Gerencia toda a estrutura da academia                    │
├──────────────────────────────────────────────────────────────┤
│                   MESTRE DE MODALIDADE                        │
│         (Professor responsável por uma arte marcial)          │
│   🥋 Gerencia graduações e alunos da sua modalidade           │
│   ❌ Sem obrigações financeiras                               │
├──────────────────────────────────────────────────────────────┤
│                       PROFESSOR                               │
│              (Ensina e promove alunos)                         │
├──────────────────────────────────────────────────────────────┤
│                       INSTRUTOR                               │
│           (Auxilia nas aulas, faz check-in)                   │
├──────────────────────────────────────────────────────────────┤
│                         ALUNO                                 │
│                   (Praticante comum)                          │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Tipos de Conta (Roles)

### 3.1 Aluno (`student`)
Conta padrão para praticantes de artes marciais.

**Funcionalidades:**
- ✅ Visualizar seu próprio perfil
- ✅ Editar informações pessoais (nome, foto, peso)
- ✅ Visualizar sua graduação atual e histórico
- ✅ Ver aulas restantes para próxima graduação
- ✅ Fazer check-in de presença
- ✅ Visualizar suas competições
- ✅ Solicitar vinculação a uma academia
- ✅ Ver informações públicas da academia
- ✅ Ver seus pagamentos/mensalidades
- ❌ Não pode promover outros usuários
- ❌ Não pode configurar graduações
- ❌ Não pode ver lista de outros alunos

---

### 3.2 Instrutor (`instructor`)
Conta para faixas avançadas que auxiliam nas aulas.

**Funcionalidades:**
- ✅ Todas as funcionalidades do Aluno
- ✅ Visualizar lista de alunos da sua modalidade
- ✅ Fazer check-in de presença dos alunos
- ✅ Visualizar progresso dos alunos
- ✅ Registrar observações sobre alunos
- ❌ Não pode promover alunos
- ❌ Não pode configurar graduações
- ❌ Não pode aprovar novos alunos

---

### 3.3 Professor (`teacher`)
Conta para professores que ministram aulas e podem promover alunos.

**Funcionalidades:**
- ✅ Todas as funcionalidades do Instrutor
- ✅ Promover alunos de graduação
- ✅ Adicionar graus nas faixas
- ✅ Aprovar/rejeitar solicitações de alunos (da sua modalidade)
- ✅ Registrar competições dos alunos
- ✅ Nomear instrutores
- ✅ Gerar relatórios de frequência dos alunos
- ❌ Não pode configurar graduações da academia
- ❌ Não pode gerenciar outros professores
- ❌ Não pode gerenciar cobranças/financeiro

---

### 3.4 Mestre de Modalidade (`modality_master`)
Professor responsável por uma arte marcial específica na academia. **Não tem obrigações financeiras**.

**Funcionalidades:**
- ✅ Todas as funcionalidades do Professor
- ✅ **Gerenciar Modalidade:**
  - Configurar sistema de graduações da modalidade
  - Definir aulas mínimas por faixa/grau
  - Definir tempo mínimo em cada faixa
  - Requisitos personalizados de promoção
- ✅ **Gerenciar Equipe da Modalidade:**
  - Nomear/remover professores da modalidade
  - Nomear/remover instrutores da modalidade
- ✅ **Gerenciar Alunos da Modalidade:**
  - Aprovar/bloquear alunos
  - Transferir alunos entre professores
  - Visualizar histórico completo
- ✅ **Relatórios da Modalidade:**
  - Frequência dos alunos
  - Progressão de graduações
- ❌ **Não tem acesso a:**
  - Configurações financeiras
  - Cobranças e pagamentos
  - Dados de outras modalidades
  - Configurações gerais da academia

---

### 3.5 Mestre Principal (`owner`)
Dono e contratante da academia. **Responsável financeiro pelo app**.

**Funcionalidades:**
- ✅ Todas as funcionalidades do Mestre de Modalidade (em todas modalidades)
- ✅ **Gerenciar Academia:**
  - Nome, logo, endereço, contato
  - Horários de funcionamento
  - Adicionar/remover modalidades
- ✅ **Gerenciar Mestres de Modalidade:**
  - Indicar professores como mestres de modalidade
  - Remover mestres de modalidade
  - Supervisionar todas as modalidades
- ✅ **Gerenciar Financeiro:**
  - Configurar planos/mensalidades
  - Visualizar todos os pagamentos
  - Gerar cobranças
  - Relatórios financeiros
  - Definir isenções (bolsistas)
- ✅ **Assinatura do App:**
  - Gerenciar plano de assinatura do app
  - Dados de pagamento
  - Limites do plano (alunos, professores)
- ✅ **Relatórios Completos:**
  - Dashboard geral da academia
  - Relatórios de todas as modalidades
  - Relatórios financeiros consolidados
  - Exportar dados

---

## 4. Estrutura de Dados

### 4.1 Modelo de Academia (`Academy`)

```dart
class Academy {
  final String id;
  final String name;
  final String? logoUrl;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? phone;
  final String? email;
  final String? website;
  
  // Dono (contratante/responsável financeiro)
  final String ownerId;
  
  // Modalidades oferecidas com seus mestres
  final List<AcademyModality> modalities;
  
  // Configurações financeiras (apenas owner tem acesso)
  final FinancialConfig? financialConfig;
  
  // Assinatura do app
  final SubscriptionInfo? subscription;
  
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Modalidade oferecida pela academia
class AcademyModality {
  final MartialArtType type;
  final String? masterId;              // Mestre da modalidade (pode ser null = owner gerencia)
  final List<String> teacherIds;       // Professores
  final List<String> instructorIds;    // Instrutores
  final GraduationConfig graduationConfig;
  final bool isActive;
}
```

### 4.2 Configuração de Graduação (`GraduationConfig`)

```dart
class GraduationConfig {
  final MartialArtType martialArtType;
  final List<BeltConfig> belts;
  final bool useDefaultConfig;      // Se true, usa config padrão do app
  final String? configuredBy;       // ID de quem configurou (owner ou modality_master)
  final DateTime? lastUpdated;
}

class BeltConfig {
  final String beltId;              // ID da faixa base (ex: bjj_blue)
  final int minClasses;             // Aulas mínimas (sobrescreve padrão)
  final int? minMonths;             // Meses mínimos (sobrescreve padrão)
  final int? minClassesPerDegree;   // Aulas por grau (se aplicável)
  final bool requiresExam;          // Exige exame de faixa?
  final double? examFee;            // Taxa do exame (se houver)
  final String? notes;              // Observações
}
```

### 4.3 Configuração Financeira (`FinancialConfig`)
**Acessível apenas pelo Owner**

```dart
class FinancialConfig {
  final String academyId;
  final List<PlanConfig> plans;
  final int paymentDueDay;          // Dia do vencimento (1-28)
  final double? enrollmentFee;      // Taxa de matrícula
  final double? annualFee;          // Taxa anual
}

class PlanConfig {
  final String id;
  final String name;                // Ex: "Mensal BJJ", "Trimestral Full"
  final PlanType type;              // single, duo, full
  final double price;
  final int durationMonths;
  final double? discount;           // Desconto percentual
  final List<MartialArtType>? includedModalities; // Modalidades incluídas (null = todas para 'full')
  final int maxModalities;          // 1 para single, 2 para duo, ilimitado para full
  final List<String> benefits;      // Lista de benefícios
  final bool isActive;
}

enum PlanType {
  single,   // 1 modalidade
  duo,      // 2 modalidades
  full,     // Todas as modalidades
}
```

### 4.4 Assinatura do App (`SubscriptionInfo`)
**Dados do contrato do Owner com o Self Dojo**

```dart
class SubscriptionInfo {
  final String planId;              // Plano contratado do app
  final String planName;            // "Basic", "Pro", "Enterprise"
  final int maxStudents;            // Limite de alunos
  final int maxTeachers;            // Limite de professores
  final int maxModalities;          // Limite de modalidades
  final List<String> features;      // Funcionalidades incluídas
  final double monthlyPrice;
  final DateTime startDate;
  final DateTime? endDate;
  final SubscriptionStatus status;
  
  // Trial
  final bool isTrial;               // Se está em período de teste
  final DateTime? trialStartDate;   // Início do trial
  final DateTime? trialEndDate;     // Fim do trial (startDate + 7 dias)
  final int trialMaxStudents;       // Limite durante trial (10)
}

enum SubscriptionStatus {
  trial,        // Em período de teste (7 dias)
  active,       // Assinatura ativa
  pastDue,      // Pagamento atrasado
  cancelled,    // Cancelada
  expired,      // Trial expirado sem conversão
}
```

### 4.5 Atualização do UserProfile

```dart
class UserProfile {
  // ... campos existentes ...
  
  final UserRole role;                    
  final String? academyId;                
  final AcademyStatus? academyStatus;     
  
  // Para mestres de modalidade
  final List<MartialArtType>? managedModalities;  // Modalidades que gerencia
  
  // Para alunos - Múltiplas modalidades
  final List<StudentModality> enrolledModalities;  // Lista de modalidades matriculadas
  final String? planId;                            // Plano contratado (single/duo/full)
  
  final DateTime? joinedAcademyAt;
  final PaymentStatus? paymentStatus;
  final DateTime? paymentDueDate;
}

/// Matrícula do aluno em uma modalidade
class StudentModality {
  final MartialArtType type;
  final String? assignedTeacherId;     // Professor responsável nesta modalidade
  final UserGraduation graduation;     // Graduação nesta modalidade
  final List<GraduationHistory> graduationHistory;
  final int totalClasses;              // Aulas nesta modalidade
  final DateTime enrolledAt;
}

enum UserRole {
  student,          // Aluno
  instructor,       // Instrutor
  teacher,          // Professor
  modalityMaster,   // Mestre de Modalidade
  owner,            // Mestre Principal (Dono)
}
```

---

## 5. Fluxos Principais

### 5.1 Fluxo de Criação de Academia (Owner)

```
1. Usuário se cadastra no app
2. Escolhe "Criar Academia"
3. Seleciona plano de assinatura do app
4. Realiza pagamento (trial gratuito?)
5. Preenche dados da academia
6. Adiciona modalidades oferecidas
7. Role muda para "owner"
8. Academia criada e ativa
```

### 5.2 Fluxo de Indicação de Mestre de Modalidade (Owner)

```
1. Owner acessa "Gerenciar Modalidades"
2. Seleciona uma modalidade
3. Escolhe "Indicar Mestre"
4. Seleciona professor da modalidade
5. Confirma indicação
6. Professor recebe notificação
7. Role do professor muda para "modality_master"
8. Professor ganha acesso às configurações da modalidade
```

### 5.3 Configuração de Graduações (Mestre de Modalidade)

```
1. Mestre acessa "Configurar Graduações"
2. Vê lista de faixas da modalidade
3. Para cada faixa pode definir:
   - Aulas mínimas para próxima faixa
   - Tempo mínimo na faixa
   - Aulas por grau (se aplicável)
   - Se exige exame
4. Salva configurações
5. Alunos veem novos requisitos
```

### 5.4 Fluxo de Vinculação (Aluno)

```
1. Aluno busca academia pelo nome/cidade
2. Visualiza modalidades oferecidas
3. Seleciona modalidade desejada
4. Envia solicitação de vinculação
5. Mestre da modalidade ou Owner aprova
6. Aluno vinculado à academia e modalidade
```

### 5.5 Fluxo de Promoção (Professor/Mestre)

```
1. Acessa lista de alunos da modalidade
2. Seleciona aluno para promover
3. Visualiza:
   - Graduação atual
   - Aulas realizadas
   - Tempo na faixa
   - Requisitos configurados pelo Mestre
4. Sistema indica se requisitos atendidos
5. Confirma promoção
6. Histórico atualizado
7. Aluno notificado
```

---

## 6. Telas e Navegação

### 6.1 Telas do Aluno
```
/home                    - Home com perfil e graduação
/profile/edit            - Editar perfil
/academy/search          - Buscar academias
/academy/request         - Solicitar vinculação
/academy/info            - Informações da academia
/payments                - Meus pagamentos
```

### 6.2 Telas do Instrutor
```
// Todas do aluno +
/modality/students       - Lista de alunos da modalidade
/modality/students/:id   - Detalhes do aluno
/modality/checkin        - Fazer check-in de alunos
```

### 6.3 Telas do Professor
```
// Todas do instrutor +
/modality/requests       - Solicitações pendentes
/modality/promote/:id    - Promover aluno
/modality/instructors    - Gerenciar instrutores
/modality/competitions   - Registrar competições
/reports/attendance      - Relatório de frequência
```

### 6.4 Telas do Mestre de Modalidade
```
// Todas do professor +
/modality/config                - Configurações da modalidade
/modality/graduation-config     - Configurar graduações
/modality/teachers              - Gerenciar professores
/modality/reports               - Relatórios da modalidade
```

### 6.5 Telas do Owner (Mestre Principal)
```
// Acesso a todas as modalidades +
/academy/manage          - Gerenciar academia
/academy/modalities      - Gerenciar modalidades
/academy/masters         - Gerenciar mestres de modalidade
/academy/subscription    - Assinatura do app
/financial/dashboard     - Dashboard financeiro
/financial/plans         - Gerenciar planos
/financial/payments      - Todos os pagamentos
/financial/reports       - Relatórios financeiros
/reports/dashboard       - Dashboard geral
```

---

## 7. Matriz de Permissões

| Ação | Aluno | Instrutor | Professor | Mestre Modal. | Owner |
|------|:-----:|:---------:|:---------:|:-------------:|:-----:|
| Ver próprio perfil | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fazer check-in próprio | ✅ | ✅ | ✅ | ✅ | ✅ |
| Ver alunos (modalidade) | ❌ | ✅ | ✅ | ✅ | ✅ |
| Check-in alunos | ❌ | ✅ | ✅ | ✅ | ✅ |
| Aprovar solicitações | ❌ | ❌ | ✅ | ✅ | ✅ |
| Promover alunos | ❌ | ❌ | ✅ | ✅ | ✅ |
| Nomear instrutores | ❌ | ❌ | ✅ | ✅ | ✅ |
| Nomear professores | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Config. graduações** | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Indicar mestre modal.** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Gerenciar academia** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Gerenciar financeiro** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Assinatura do app** | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 8. Regras de Negócio

### 8.1 Mestre de Modalidade
- [ ] Só pode gerenciar modalidades que foi indicado
- [ ] Não tem acesso a dados financeiros
- [ ] Não pode adicionar/remover modalidades
- [ ] Pode ser removido pelo Owner a qualquer momento
- [ ] Quando removido, volta a ser Professor

### 8.2 Owner (Mestre Principal)
- [ ] Único responsável financeiro
- [ ] Pode gerenciar todas as modalidades diretamente
- [ ] Pode indicar mestres de modalidade para delegar
- [ ] Assinatura do app é vinculada ao Owner
- [ ] Se assinatura cancelada, academia fica inativa

### 8.3 Configurações de Graduação
- [ ] Mestre de Modalidade pode configurar sua modalidade
- [ ] Owner pode configurar qualquer modalidade
- [ ] Alterações não afetam histórico (apenas novos requisitos)
- [ ] Pode voltar para configuração padrão do app

### 8.4 Limites por Plano de Assinatura (Academia)
```
┌─────────────┬─────────┬──────────┬──────────────┐
│   Plano     │ Alunos  │ Profess. │ Modalidades  │
├─────────────┼─────────┼──────────┼──────────────┤
│ Basic       │   50    │    3     │      2       │
│ Pro         │  200    │   10     │      5       │
│ Enterprise  │ Ilimit. │ Ilimit.  │   Ilimit.    │
└─────────────┴─────────┴──────────┴──────────────┘
```

### 8.5 Planos do Aluno (Modalidades)
O aluno pode treinar uma ou mais modalidades dependendo do plano contratado na academia.

```
┌─────────────────┬──────────────┬─────────────────────────────┐
│   Plano Aluno   │ Modalidades  │ Exemplo                     │
├─────────────────┼──────────────┼─────────────────────────────┤
│ Single          │      1       │ Apenas BJJ                  │
│ Duo             │      2       │ BJJ + Muay Thai             │
│ Full            │    Todas     │ Acesso a todas modalidades  │
└─────────────────┴──────────────┴─────────────────────────────┘
```

- Cada modalidade tem sua própria graduação
- Aluno tem histórico separado por modalidade
- Check-in registra qual modalidade treinou

### 8.6 Trial do Owner
- [ ] **7 dias** de período gratuito para testar
- [ ] Acesso completo durante o trial
- [ ] Limite de 10 alunos durante trial
- [ ] Após 7 dias: converte para plano pago ou academia inativa
- [ ] Dados mantidos por 30 dias após expiração

---

## 9. Firestore Collections

```
/users/{userId}
  - role: string (student|instructor|teacher|modalityMaster|owner)
  - academyId: string?
  - academyStatus: string?
  - managedModalities: string[]?   // Para mestres de modalidade
  - enrolledModality: string?      // Para alunos
  - assignedTeacherId: string?
  - paymentStatus: string?

/academies/{academyId}
  - name: string
  - ownerId: string                // Dono/contratante
  - modalities: array              // Lista de AcademyModality
  - financialConfig: map?
  - subscription: map              // Assinatura do app
  - isActive: boolean

/academies/{academyId}/students/{odiaré}
  - modalityType: string
  - joinedAt: timestamp
  - assignedTeacherId: string

/academies/{academyId}/requests/{requestId}
  - userId: string
  - modalityType: string
  - status: string
  - requestedAt: timestamp

/academies/{academyId}/payments/{paymentId}
  - userId: string
  - amount: number
  - status: string
  // Apenas owner pode ver/gerenciar

/academies/{academyId}/promotions/{promotionId}
  - userId: string
  - modalityType: string
  - fromBeltId: string
  - toBeltId: string
  - promotedBy: string
```

---

## 10. Próximos Passos (Implementação)

### Fase 1 - Fundação (Roles Básicos)
- [ ] Atualizar enum UserRole (adicionar modalityMaster, owner)
- [ ] Atualizar UserProfile com novos campos
- [ ] Criar modelo Academy com modalities
- [ ] Criar modelo AcademyModality
- [ ] Criar modelo GraduationConfig

### Fase 2 - Owner & Academia
- [ ] Tela de criação de academia
- [ ] Tela de seleção de plano/assinatura
- [ ] Tela de gerenciamento de academia
- [ ] Adicionar/remover modalidades

### Fase 3 - Mestre de Modalidade
- [ ] Fluxo de indicação pelo Owner
- [ ] Tela de configuração de graduações
- [ ] Gerenciamento de professores/instrutores
- [ ] Relatórios da modalidade

### Fase 4 - Aluno & Vinculação
- [ ] Busca por academia e modalidade
- [ ] Solicitação de vinculação
- [ ] Aprovação pelo Mestre/Professor

### Fase 5 - Financeiro (Owner)
- [ ] Configuração de planos
- [ ] Registro de pagamentos
- [ ] Dashboard financeiro
- [ ] Relatórios

---

## 11. Questões Resolvidas

| Questão | Decisão |
|---------|---------|
| Múltiplas artes marciais por academia? | ✅ Sim, com mestre para cada modalidade |
| Quem configura graduações? | Mestre de Modalidade ou Owner |
| Responsável financeiro? | Apenas Owner (Mestre Principal) |
| Professor pode ser mestre sem pagar? | ✅ Sim, indicado pelo Owner |
| Aluno em múltiplas modalidades? | ✅ Sim, depende do plano contratado (Single/Duo/Full) |
| Trial do Owner? | ✅ 7 dias gratuitos, limite 10 alunos |

---

## 12. Questões em Aberto

1. **Transferência de academia:**
   - Aluno pode transferir para outra academia?
   - Mantém histórico de graduações?

2. **Integração de pagamento:**
   - Como Owner paga assinatura do app?
   - Integrar com Stripe? PagSeguro? Pix?

---

## Aprovação

- [ ] Requisitos revisados
- [ ] Hierarquia de roles aprovada
- [ ] Separação financeira aprovada
- [ ] Pronto para implementação
