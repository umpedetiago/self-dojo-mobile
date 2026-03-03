## Migração de Promoções e Membership (fase 3 – plano de alto nível)

### Objetivo
- Levar os fluxos de **promoção de faixa** e **membership de academia** do mobile para dependerem exclusivamente da Backend API, alinhados com os modelos já usados no check-in e no perfil (`/v1/me`).

### Escopo principal
- **Promoções (graduações)**:
  - Backend já expõe:
    - `POST /v1/student-modalities/{studentModalityId}/promotions`
    - `GET /v1/student-modalities/{studentModalityId}/graduation-history`
  - Mobile deve:
    - Usar sempre esses endpoints ao promover um aluno.
    - Exibir o histórico usando a resposta `GraduationHistoryResponse` (já mapeada em `StudentsRepositoryHybrid._mapStudentModalityFromBackend`).
    - Parar de escrever diretamente em estruturas legadas (ex.: `graduationHistory` em Firestore).

- **Membership & academias**:
  - Backend já expõe:
    - `GET/POST /v1/academies/{academyId}/membership-requests`
    - `DELETE /v1/academies/{academyId}/membership-requests/me`
    - `POST /v1/academies/{academyId}/membership-requests/{memberId}/approve|reject`
    - `GET /v1/academies/{academyId}/students` e `GET /v1/academies/{academyId}/students/{memberId}`
  - Mobile deve:
    - Usar esses endpoints para:
      - Solicitar entrada em academia.
      - Cancelar pedido.
      - Aprovar/rejeitar alunos (lado owner).
      - Listar alunos e detalhes para telas de gestão.

### Passos propostos
1. **Revisar telas atuais** de promoções/membership no mobile:
   - Identificar pontos onde ainda se escreve em Firestore diretamente (por exemplo, atualizando `graduationHistory` ou status de membro).
2. **Criar/adaptar repositórios**:
   - Ampliar `StudentsRepositoryHybrid` para expor métodos de:
     - `getGraduationHistory(studentModalityId)`
     - `getStudent(memberId)` usando backend (quando aplicável).
   - Criar (ou ampliar) um repositório `MembershipRepositoryHybrid` para encapsular membership requests (`/membership-requests`).
3. **Refatorar ViewModels** de promoção:
   - Apontar ações de “Promover aluno” para `promoteStudent` (backend).
   - Atualizar UI de histórico de graduações para consumir apenas dados vindos dos endpoints v1.
4. **Refatorar fluxos de membership**:
   - Em telas de:
     - “Entrar em academia”: usar `POST /membership-requests`.
     - “Cancelar pedido”: usar `DELETE /membership-requests/me`.
     - “Gerenciar alunos”: usar `GET /students` + ações de approve/reject.
5. **Remover ou isolar definitivamente o legado**:
   - Encapsular qualquer acesso restante ao Supabase/Firestore em camadas específicas que possam ser desligadas depois.

### Testes recomendados
- **Fluxos de promoção**:
  - Promover aluno em diferentes modalidades e verificar:
    - Atualização de `belt_id`/`degree` e contadores via `/v1/me`.
    - Histórico correto em `/graduation-history`.
- **Fluxos de membership**:
  - Criar, aprovar, rejeitar e cancelar membership requests via app.
  - Verificar consistência com o que a Web/Admin enxerga (se existir).

