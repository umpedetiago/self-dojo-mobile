# Funcionalidades do Self Dojo Mobile

Documento completo descrevendo todas as funcionalidades implementadas no aplicativo Self Dojo Mobile.

---

## 📱 Índice

1. [Autenticação](#1-autenticação)
2. [Perfil do Usuário](#2-perfil-do-usuário)
3. [Tela Home](#3-tela-home)
4. [Sistema de Academias](#4-sistema-de-academias)
5. [Gerenciamento de Modalidades](#5-gerenciamento-de-modalidades)
6. [Configuração de Graduações](#6-configuração-de-graduações)
7. [Gerenciamento de Alunos](#7-gerenciamento-de-alunos)
8. [Solicitações de Entrada](#8-solicitações-de-entrada)
9. [Gerenciamento de Equipe](#9-gerenciamento-de-equipe)
10. [Horários de Aulas](#10-horários-de-aulas)
11. [Sistema de Check-in](#11-sistema-de-check-in)
12. [Sistema de Roles (Papéis)](#12-sistema-de-roles-papéis)
13. [Assinatura e Planos](#13-assinatura-e-planos)

---

## 1. Autenticação

### 1.1 Login
- **Tela:** `/login`
- **Funcionalidades:**
  - Login com email e senha
  - Validação de campos obrigatórios
  - Tratamento de erros de autenticação
  - Redirecionamento automático após login bem-sucedido
  - Integração com Firebase Authentication

### 1.2 Registro
- **Tela:** `/register`
- **Funcionalidades:**
  - Criação de nova conta com email e senha
  - Seleção de role durante o registro:
    - **Aluno (student)**: Conta padrão para praticantes
    - **Owner**: Dono/administrador de academia
  - Seleção de arte marcial preferida
  - Validação de formulário
  - Criação automática de perfil no Supabase após registro

### 1.3 Splash Screen
- **Tela:** `/splash`
- **Funcionalidades:**
  - Verificação automática do estado de autenticação
  - Redirecionamento inteligente:
    - Usuário autenticado → Home
    - Usuário não autenticado → Login
  - Tela de carregamento inicial

---

## 2. Perfil do Usuário

### 2.1 Visualização do Perfil
- **Localização:** Tela Home
- **Informações exibidas:**
  - Foto de perfil
  - Nome completo
  - Email
  - Arte marcial principal
  - Graduação atual (faixa e grau)
  - Academia vinculada (se houver)
  - Professor responsável
  - Categoria de peso
  - Data de início dos treinos

### 2.2 Edição de Perfil
- **Tela:** `/profile/edit`
- **Funcionalidades:**
  - Edição de nome completo
  - Upload de foto de perfil (Supabase Storage)
  - Edição de peso e categoria
  - Edição de informações pessoais
  - Atualização em tempo real
  - Validação de campos

---

## 3. Tela Home

### 3.1 Dashboard Principal
- **Tela:** `/home`
- **Funcionalidades:**

#### 3.1.1 Header do Perfil
- Foto de perfil
- Nome do usuário
- Botão de editar perfil
- Botão de logout (com confirmação)

#### 3.1.2 Exibição de Graduação
- Faixa atual com cor representativa
- Grau atual (se aplicável)
- Arte marcial
- Visualização visual da faixa

#### 3.1.3 Cards de Estatísticas
- **Total de Aulas:** Número total de aulas realizadas
  - Clicável para alunos (abre histórico de check-in)
- **Tempo de Treino:** Duração desde o início
- **Competições:** Número de competições registradas
- **Próxima Faixa:** Aulas restantes para promoção
  - Ou indicação de "Graduação Máxima" se já estiver na faixa mais alta

#### 3.1.4 Ações Rápidas
- **Minha Academia:** 
  - Para Owners: Acessa gerenciamento
  - Para Alunos: Visualiza informações da academia
- **Buscar Academia:** Busca academias disponíveis
- **Check-in:** Realiza check-in de presença
- **Histórico:** Visualiza histórico de check-ins (apenas alunos)
- **Criar Academia:** Criação de nova academia (apenas para usuários sem academia)

#### 3.1.5 Informações Adicionais
- Arte marcial praticada
- Academia vinculada
- Professor responsável
- Categoria de peso
- Data de início

#### 3.1.6 Modalidades Matriculadas
- Lista todas as modalidades em que o aluno está matriculado
- Exibe faixa atual em cada modalidade
- Visualização separada por modalidade

#### 3.1.7 Histórico de Graduações
- Últimas 5 graduações realizadas
- Data de cada promoção
- Faixa e grau alcançados
- Visualização cronológica

---

## 4. Sistema de Academias

### 4.1 Criação de Academia
- **Tela:** `/academy/create`
- **Funcionalidades:**
  - Cadastro de nome da academia
  - Upload de logo (opcional)
  - Descrição da academia
  - Endereço completo
  - Cidade e estado
  - Telefone de contato
  - Email de contato
  - Website (opcional)
  - Criação automática do registro no banco
  - Atribuição do role "owner" ao criador

### 4.2 Seleção de Academia
- **Tela:** `/academy/select`
- **Funcionalidades:**
  - Lista todas as academias do owner
  - Cards visuais com logo e nome
  - Seleção rápida para alternar entre academias
  - Indicador de academia atual
  - Navegação direta para gerenciamento

### 4.3 Gerenciamento de Academia
- **Tela:** `/academy/manage` ou `/academy/manage/:academyId`
- **Funcionalidades:**

#### 4.3.1 Dashboard do Owner
- **Header:**
  - Logo da academia
  - Nome da academia
  - Modalidades oferecidas
  - Botões de configuração e perfil

#### 4.3.2 Banner de Trial
- Exibido quando em período de trial
- Dias restantes do trial
- Limite de alunos durante trial (10)
- Botão para assinar plano

#### 4.3.3 Cards de Estatísticas
- **Alunos:** Total de alunos / Limite do plano
- **Modalidades:** Total de modalidades / Limite do plano
- **Professores:** Total de professores / Limite do plano
- **Solicitações:** Número de solicitações pendentes

#### 4.3.4 Menu de Gerenciamento
- **Modalidades:** Gerenciar artes marciais e graduações
- **Alunos:** Ver e gerenciar alunos
- **Solicitações:** Aprovar novos alunos
- **Equipe:** Professores e instrutores
- **Horários de Aulas:** Gerenciar horários e check-in
- **Editar Perfil:** Dados do owner
- **Editar Academia:** Informações da academia
- **Assinatura:** Gerenciar plano

#### 4.3.5 Drawer (Menu Lateral)
- Editar academia
- Editar perfil
- Criar nova academia (se permitido pelo plano)
- Minhas academias (se tiver múltiplas)
- Voltar para home

### 4.4 Edição de Academia
- **Tela:** `/academy/edit/:academyId`
- **Funcionalidades:**
  - Edição de todos os dados da academia
  - Atualização de logo
  - Modificação de informações de contato
  - Salvamento de alterações

### 4.5 Busca de Academias
- **Tela:** `/academy/search`
- **Funcionalidades:**
  - Busca por nome da academia
  - Busca por cidade
  - Filtro por modalidades oferecidas
  - Lista de resultados com:
    - Logo da academia
    - Nome
    - Cidade e estado
    - Modalidades disponíveis
    - Status (ativa/inativa)
  - Visualização de detalhes
  - Solicitação de vinculação (para alunos)

---

## 5. Gerenciamento de Modalidades

### 5.1 Lista de Modalidades
- **Tela:** `/academy/modalities`
- **Funcionalidades:**
  - Visualização de todas as modalidades da academia
  - Status de cada modalidade (ativa/inativa)
  - Mestre responsável por cada modalidade
  - Número de alunos por modalidade
  - Adição de novas modalidades
  - Ativação/desativação de modalidades

### 5.2 Configuração de Modalidade
- **Funcionalidades:**
  - Indicar mestre de modalidade
  - Gerenciar professores da modalidade
  - Gerenciar instrutores da modalidade
  - Configurar graduações específicas
  - Visualizar alunos da modalidade

---

## 6. Configuração de Graduações

### 6.1 Tela de Configuração
- **Tela:** `/academy/modalities/:type/graduation`
- **Funcionalidades:**
  - Visualização de todas as faixas da arte marcial
  - Configuração personalizada por faixa:
    - **Aulas mínimas:** Número mínimo de aulas para próxima faixa
    - **Tempo mínimo:** Meses mínimos na faixa atual
    - **Aulas por grau:** Aulas necessárias para cada grau
    - **Exige exame:** Se a promoção requer exame
    - **Taxa de exame:** Valor do exame (se aplicável)
    - **Observações:** Notas adicionais
  - Usar configuração padrão do app ou personalizar
  - Salvamento de configurações
  - Aplicação apenas para novos requisitos (não afeta histórico)

---

## 7. Gerenciamento de Alunos

### 7.1 Lista de Alunos
- **Tela:** `/academy/students`
- **Funcionalidades:**
  - Lista completa de todos os alunos da academia
  - Busca por nome
  - Filtro por modalidade
  - Cards com informações:
    - Foto do aluno
    - Nome completo
    - Modalidades matriculadas
    - Faixa atual em cada modalidade
    - Status (ativo/inativo)
  - Navegação para detalhes do aluno

### 7.2 Detalhes do Aluno
- **Tela:** `/academy/students/:memberId`
- **Funcionalidades:**

#### 7.2.1 Informações Pessoais
- Foto de perfil
- Nome completo
- Email
- Telefone (se disponível)
- Data de entrada na academia

#### 7.2.2 Modalidades Matriculadas
- Lista de todas as modalidades do aluno
- Para cada modalidade:
  - Faixa atual
  - Grau atual
  - Total de aulas
  - Professor responsável
  - Data de matrícula
  - Histórico de graduações
- Adicionar nova modalidade ao aluno
- Remover modalidade (se aplicável)

#### 7.2.3 Estatísticas
- Total de aulas realizadas
- Tempo de treino
- Competições participadas
- Progresso para próxima faixa

#### 7.2.4 Histórico de Check-ins
- Lista de presenças registradas
- Data e horário de cada check-in
- Modalidade treinada
- Horário da aula

#### 7.2.5 Ações Disponíveis
- Promover aluno (para professores/mestres)
- Editar informações
- Registrar competição
- Adicionar observações

---

## 8. Solicitações de Entrada

### 8.1 Tela de Solicitações
- **Tela:** `/academy/requests`
- **Funcionalidades:**
  - Lista de solicitações pendentes
  - Filtro por modalidade
  - Informações de cada solicitação:
    - Foto e nome do solicitante
    - Modalidade desejada
    - Data da solicitação
    - Status (pendente/aprovada/rejeitada)
  - Visualização de detalhes do solicitante

### 8.2 Aprovação/Rejeição
- **Funcionalidades:**
  - Aprovar solicitação:
    - Vincula aluno à academia
    - Matricula na modalidade solicitada
    - Atribui professor responsável (se aplicável)
    - Notifica o aluno
  - Rejeitar solicitação:
    - Remove a solicitação
    - Opção de adicionar motivo (futuro)
  - Aprovação em lote (futuro)

---

## 9. Gerenciamento de Equipe

### 9.1 Tela de Equipe
- **Tela:** `/academy/teachers`
- **Funcionalidades:**
  - Lista de todos os membros da equipe
  - Separação por categoria:
    - **Mestres de Modalidade**
    - **Professores**
    - **Instrutores**
  - Informações de cada membro:
    - Foto e nome
    - Role atual
    - Modalidades atribuídas
    - Número de alunos sob responsabilidade
  - Adicionar novos membros
  - Promover/demover membros
  - Remover membros da equipe

### 9.2 Gerenciamento de Professores
- **Funcionalidades:**
  - Atribuir professores a modalidades
  - Remover professores de modalidades
  - Visualizar alunos sob responsabilidade
  - Promover instrutor para professor
  - Indicar professor como mestre de modalidade

### 9.3 Gerenciamento de Instrutores
- **Funcionalidades:**
  - Atribuir instrutores a modalidades
  - Remover instrutores
  - Visualizar permissões
  - Promover aluno para instrutor

---

## 10. Horários de Aulas

### 10.1 Tela de Horários
- **Tela:** `/academy/schedules`
- **Funcionalidades:**
  - Lista de todos os horários cadastrados
  - Visualização por dia da semana
  - Informações de cada horário:
    - Horário de início e fim
    - Modalidade (ou "Todas")
    - Tipo de aula (regular, especial, etc.)
    - Professor responsável
    - Status (ativo/inativo)
  - Adicionar novo horário
  - Editar horário existente
  - Remover horário
  - Ativar/desativar horário

### 10.2 Cadastro de Horário
- **Funcionalidades:**
  - Seleção de dia da semana
  - Horário de início
  - Horário de fim
  - Modalidade específica ou "Todas as modalidades"
  - Tipo de aula
  - Professor responsável (opcional)
  - Ativar/desativar disponibilidade para check-in

---

## 11. Sistema de Check-in

### 11.1 Fazer Check-in
- **Tela:** `/checkin`
- **Funcionalidades:**
  - Lista de horários disponíveis para o dia
  - Filtro automático por horário atual
  - Informações de cada aula:
    - Horário (início e fim)
    - Modalidade
    - Tipo de aula
    - Professor
    - Status (disponível/já passou)
  - Confirmação de check-in
  - Validação de duplicidade
  - Registro no banco de dados
  - Notificação de sucesso/erro

### 11.2 Histórico de Check-ins
- **Tela:** `/checkin/history`
- **Funcionalidades:**
  - Lista completa de check-ins realizados
  - Filtro por data
  - Filtro por modalidade
  - Informações de cada check-in:
    - Data e horário
    - Modalidade treinada
    - Horário da aula
    - Status (confirmado)
  - Estatísticas:
    - Total de aulas no mês
    - Total de aulas por modalidade
    - Frequência semanal
  - Visualização em lista ou calendário

---

## 12. Sistema de Roles (Papéis)

O app possui um sistema hierárquico de roles que define permissões e funcionalidades:

### 12.1 Aluno (student)
- **Permissões:**
  - Ver próprio perfil
  - Editar informações pessoais
  - Fazer check-in próprio
  - Ver histórico de check-ins
  - Buscar academias
  - Solicitar vinculação
  - Ver informações da academia
- **Restrições:**
  - Não pode ver outros alunos
  - Não pode fazer check-in de outros
  - Não pode promover alunos
  - Não pode configurar graduações

### 12.2 Instrutor (instructor)
- **Permissões:**
  - Todas as permissões do Aluno
  - Ver lista de alunos da modalidade
  - Fazer check-in de alunos
  - Ver progresso dos alunos
- **Restrições:**
  - Não pode promover alunos
  - Não pode aprovar solicitações
  - Não pode configurar graduações

### 12.3 Professor (teacher)
- **Permissões:**
  - Todas as permissões do Instrutor
  - Promover alunos de graduação
  - Adicionar graus nas faixas
  - Aprovar/rejeitar solicitações
  - Registrar competições
  - Nomear instrutores
- **Restrições:**
  - Não pode configurar graduações da academia
  - Não pode gerenciar outros professores

### 12.4 Mestre de Modalidade (modality_master)
- **Permissões:**
  - Todas as permissões do Professor
  - Configurar sistema de graduações da modalidade
  - Definir requisitos de promoção
  - Gerenciar professores da modalidade
  - Gerenciar instrutores da modalidade
  - Relatórios da modalidade
- **Restrições:**
  - Apenas para modalidade indicada
  - Não tem acesso a dados financeiros
  - Não pode adicionar/remover modalidades

### 12.5 Owner (Mestre Principal)
- **Permissões:**
  - Todas as permissões do Mestre de Modalidade (em todas modalidades)
  - Gerenciar academia completa
  - Adicionar/remover modalidades
  - Indicar mestres de modalidade
  - Gerenciar assinatura do app
  - Acesso a todas as funcionalidades administrativas
- **Responsabilidades:**
  - Responsável financeiro pelo app
  - Gerencia toda a estrutura da academia

---

## 13. Assinatura e Planos

### 13.1 Gerenciamento de Assinatura
- **Tela:** `/academy/subscription`
- **Funcionalidades:**
  - Visualização do plano atual
  - Status da assinatura (trial/ativa/vencida)
  - Limites do plano:
    - Número máximo de alunos
    - Número máximo de professores
    - Número máximo de modalidades
  - Dias restantes do trial (se aplicável)
  - Histórico de pagamentos
  - Renovação de assinatura
  - Upgrade/downgrade de plano

### 13.2 Planos Disponíveis
- **Basic:**
  - 50 alunos
  - 3 professores
  - 2 modalidades
- **Pro:**
  - 200 alunos
  - 10 professores
  - 5 modalidades
- **Enterprise:**
  - Alunos ilimitados
  - Professores ilimitados
  - Modalidades ilimitadas
  - Múltiplas academias

### 13.3 Período de Trial
- **Duração:** 7 dias gratuitos
- **Limites durante trial:**
  - Máximo de 10 alunos
  - Acesso completo às funcionalidades
- **Após trial:**
  - Conversão para plano pago
  - Ou academia fica inativa
  - Dados mantidos por 30 dias

---

## 🔧 Funcionalidades Técnicas

### Backend
- **Supabase (PostgreSQL):** Banco de dados principal
- **Supabase Storage:** Armazenamento de imagens
- **Firebase Authentication:** Autenticação de usuários
- **Row Level Security (RLS):** Segurança no banco de dados

### Arquitetura
- **MVVM (Model-View-ViewModel):** Padrão arquitetural
- **Provider:** Gerenciamento de estado
- **GoRouter:** Navegação type-safe
- **Result Pattern:** Tratamento de erros
- **Command Pattern:** Ações assíncronas

### Componentes Reutilizáveis
- AppButton
- AppCard
- AppInput
- AppLoadingIndicator
- AppSectionTitle
- AppDivider
- AppIconContainer
- AppInfoRow

---

## 📊 Estatísticas do App

- **Telas:** 17+
- **ViewModels:** 8
- **Repositórios:** 8 (4 interfaces + 4 implementações)
- **Modelos de Domínio:** 12+
- **Tabelas no Banco:** 10+
- **Views SQL:** 2
- **Functions SQL:** 3

---

## 🚀 Funcionalidades Futuras

### Planejadas
- Notificações push
- Sistema de pagamentos integrado
- Relatórios avançados
- Exportação de dados
- Integração com calendário
- Chat entre membros
- Sistema de avaliações
- Certificados digitais
- Integração com redes sociais

---

*Última atualização: Janeiro 2026*
