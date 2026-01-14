# Roadmap - Self Dojo Mobile

Planejamento detalhado das próximas implementações.

---

## 📍 Estado Atual do Projeto

O projeto está na **Fase 1.5** - a fundação está implementada, mas precisa de validação e testes antes de avançar para novas funcionalidades.

### ✅ Implementado
- Estrutura base do app (MVVM + Clean Architecture)
- Autenticação com Firebase
- Backend Supabase configurado
- CRUD básico de perfil e academia
- Sistema de roles definido
- Modelos de domínio completos

### ⚠️ Precisa Validação
- Fluxo completo de registro
- Integração Supabase funcionando end-to-end
- Upload de imagens
- Busca de academias

---

## 🗓️ Sprint 1 - Estabilização (1-2 semanas)

### Objetivo
Garantir que a base está sólida antes de adicionar novas funcionalidades.

### Tarefas

#### 1.1 Correções Pendentes
- [ ] Commitar fix do `uploadProfileImage` no ProfileRepositorySupabase
- [ ] Revisar todos os repositórios Supabase para padrão consistente
- [ ] Verificar tratamento de erros em todos os repositórios

#### 1.2 Testes Manuais
- [ ] Testar registro de novo usuário como Student
- [ ] Testar registro de novo usuário como Owner
- [ ] Testar criação de academia
- [ ] Testar busca de academias
- [ ] Testar solicitação de entrada em academia
- [ ] Testar upload de foto de perfil

#### 1.3 Configuração Supabase
- [ ] Criar bucket `avatars` no Storage (se não existir)
- [ ] Configurar policies de Storage
- [ ] Revisar e testar RLS policies
- [ ] Verificar se schema está aplicado corretamente

#### 1.4 Melhorias de UX
- [ ] Loading states em todas as telas
- [ ] Mensagens de erro amigáveis
- [ ] Empty states (listas vazias)
- [ ] Feedback visual para ações (snackbars)

### Entregáveis
- App funcionando end-to-end para fluxos básicos
- Documentação atualizada de como testar

---

## 🗓️ Sprint 2 - Fluxo do Owner (2 semanas)

### Objetivo
Completar a experiência do dono da academia.

### Tarefas

#### 2.1 Dashboard do Owner
- [ ] Tela de dashboard com métricas:
  - Total de alunos
  - Total de professores
  - Alunos por modalidade
  - Solicitações pendentes
- [ ] Gráficos simples (opcional)

#### 2.2 Gerenciamento de Modalidades
- [ ] Adicionar/remover modalidades da academia
- [ ] Configurar graduações por modalidade
- [ ] Indicar mestre de modalidade

#### 2.3 Gerenciamento de Membros
- [ ] Lista de todos os membros da academia
- [ ] Filtros: por role, por modalidade, por status
- [ ] Ações: aprovar, suspender, promover role

#### 2.4 Aprovação de Solicitações
- [ ] Lista de solicitações pendentes
- [ ] Aprovar com seleção de modalidade
- [ ] Rejeitar com motivo

### Entregáveis
- Owner consegue gerenciar completamente sua academia
- Fluxo de aprovação de alunos funcionando

---

## 🗓️ Sprint 3 - Fluxo do Aluno (2 semanas)

### Objetivo
Completar a experiência do aluno.

### Tarefas

#### 3.1 Home do Aluno
- [ ] Exibir graduação atual com visual bonito
- [ ] Mostrar progresso para próxima faixa
- [ ] Estatísticas: aulas totais, tempo na faixa atual
- [ ] Informações da academia vinculada

#### 3.2 Vinculação à Academia
- [ ] Melhorar busca de academias (por cidade, nome)
- [ ] Ver detalhes da academia antes de solicitar
- [ ] Ver modalidades disponíveis
- [ ] Solicitar entrada com seleção de modalidade

#### 3.3 Perfil do Aluno
- [ ] Editar informações pessoais
- [ ] Ver histórico de graduações
- [ ] Ver plano atual (quando implementado)

### Entregáveis
- Aluno consegue se vincular a uma academia
- Visualização clara do progresso

---

## 🗓️ Sprint 4 - Sistema de Check-in (2 semanas)

### Objetivo
Implementar controle de frequência.

### Tarefas

#### 4.1 Check-in do Aluno
- [ ] Botão de check-in na home
- [ ] Seleção de modalidade (se múltiplas)
- [ ] Confirmação com horário
- [ ] Histórico de check-ins

#### 4.2 Check-in pelo Instrutor/Professor
- [ ] Lista de alunos para fazer check-in
- [ ] Check-in em lote
- [ ] QR Code para check-in rápido (opcional)

#### 4.3 Contagem de Aulas
- [ ] Incrementar automaticamente ao fazer check-in
- [ ] Atualizar `classes_at_current_belt`
- [ ] Atualizar `total_classes`

### Entregáveis
- Sistema de frequência funcionando
- Contagem de aulas automática

---

## 🗓️ Sprint 5 - Sistema de Promoções (2 semanas)

### Objetivo
Permitir que professores promovam alunos.

### Tarefas

#### 5.1 Verificação de Requisitos
- [ ] Buscar configuração de graduação da modalidade
- [ ] Calcular se aluno atingiu requisitos
- [ ] Exibir indicador visual de "pronto para promoção"

#### 5.2 Fluxo de Promoção
- [ ] Professor seleciona aluno
- [ ] Sistema mostra requisitos vs atual
- [ ] Seleção da nova faixa/grau
- [ ] Confirmação com observações
- [ ] Registro no histórico

#### 5.3 Notificações
- [ ] Notificar aluno sobre promoção
- [ ] Histórico de promoções visível para aluno

### Entregáveis
- Professores podem promover alunos
- Histórico de graduações completo

---

## 🗓️ Sprint 6 - Relatórios Básicos (1-2 semanas)

### Objetivo
Fornecer insights para gestão da academia.

### Tarefas

#### 6.1 Relatório de Frequência
- [ ] Frequência por aluno
- [ ] Frequência por período
- [ ] Frequência por modalidade

#### 6.2 Relatório de Graduações
- [ ] Promoções realizadas
- [ ] Alunos prontos para promoção
- [ ] Tempo médio em cada faixa

#### 6.3 Exportação
- [ ] Exportar relatórios em PDF/CSV (opcional)

### Entregáveis
- Dashboard com métricas principais
- Relatórios básicos funcionando

---

## 🔮 Futuro (Backlog)

### Financeiro
- [ ] Configuração de planos de mensalidade
- [ ] Registro de pagamentos
- [ ] Dashboard financeiro
- [ ] Integração com gateway de pagamento

### Notificações
- [ ] Push notifications (Firebase)
- [ ] Lembretes de treino
- [ ] Avisos da academia

### Competições
- [ ] Registro de competições
- [ ] Resultados e medalhas
- [ ] Histórico do atleta

### Multi-plataforma
- [ ] Web app para gestão
- [ ] Sincronização offline

### Integrações
- [ ] WhatsApp para notificações
- [ ] Calendário de aulas
- [ ] Sistema de agendamento

---

## 📊 Estimativas

| Sprint | Duração Estimada | Prioridade |
|--------|------------------|------------|
| 1 - Estabilização | 1-2 semanas | 🔴 Crítica |
| 2 - Fluxo Owner | 2 semanas | 🔴 Alta |
| 3 - Fluxo Aluno | 2 semanas | 🔴 Alta |
| 4 - Check-in | 2 semanas | 🟡 Média |
| 5 - Promoções | 2 semanas | 🟡 Média |
| 6 - Relatórios | 1-2 semanas | 🟢 Baixa |

**Total estimado para MVP:** 10-12 semanas

---

## 🎯 MVP (Minimum Viable Product)

Para um MVP funcional, precisamos completar:

1. ✅ Autenticação
2. ✅ Criação de academia
3. ⚠️ Vinculação de alunos
4. ⚠️ Check-in de frequência
5. ⚠️ Promoção de graduação
6. ❌ Relatório básico

**MVP estimado:** Sprints 1-5 (~10 semanas)

---

## 📝 Critérios de Aceite por Funcionalidade

### Registro/Login
- [ ] Usuário consegue criar conta
- [ ] Usuário consegue fazer login
- [ ] Erro claro quando credenciais inválidas
- [ ] Recuperação de senha funcionando

### Academia (Owner)
- [ ] Owner consegue criar academia
- [ ] Owner consegue editar informações
- [ ] Owner consegue adicionar modalidades
- [ ] Owner consegue ver lista de membros
- [ ] Owner consegue aprovar/rejeitar solicitações

### Aluno
- [ ] Aluno consegue buscar academias
- [ ] Aluno consegue solicitar entrada
- [ ] Aluno vê sua graduação atual
- [ ] Aluno consegue fazer check-in
- [ ] Aluno vê histórico de aulas

### Professor
- [ ] Professor vê lista de alunos da sua modalidade
- [ ] Professor consegue fazer check-in de alunos
- [ ] Professor consegue promover alunos
- [ ] Professor vê requisitos de promoção

---

*Última atualização: Janeiro 2026*


