-- ============================================
-- CLASS SCHEDULES (Horários de Aulas)
-- ============================================

CREATE TABLE class_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  academy_id UUID NOT NULL REFERENCES academies(id) ON DELETE CASCADE,
  modality_id UUID REFERENCES academy_modalities(id) ON DELETE CASCADE, -- NULL = para todas as modalidades
  
  -- Dia da semana (0 = domingo, 1 = segunda, ..., 6 = sábado)
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  
  -- Horário
  start_time TIME NOT NULL,
  end_time TIME NOT NULL CHECK (end_time > start_time),
  
  -- Tipo de aula
  class_type VARCHAR(50) DEFAULT 'regular', -- 'regular', 'sparring', 'open_mat', 'kids', etc
  
  -- Professor responsável (opcional)
  instructor_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Configurações
  is_active BOOLEAN DEFAULT TRUE,
  max_students INTEGER, -- NULL = sem limite
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_class_schedules_academy ON class_schedules(academy_id);
CREATE INDEX idx_class_schedules_modality ON class_schedules(modality_id);
CREATE INDEX idx_class_schedules_day ON class_schedules(day_of_week);
CREATE INDEX idx_class_schedules_active ON class_schedules(is_active);

-- Trigger para updated_at
CREATE TRIGGER tr_class_schedules_updated_at 
  BEFORE UPDATE ON class_schedules 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Habilita RLS
ALTER TABLE class_schedules ENABLE ROW LEVEL SECURITY;

-- Policies - Academy owners e professores podem gerenciar horários
CREATE POLICY "Academy owners can manage schedules" ON class_schedules
  FOR ALL USING (
    academy_id IN (
      SELECT id FROM academies WHERE owner_id IN (
        SELECT id FROM users WHERE firebase_uid = current_setting('request.jwt.claims')::json->>'sub'
      )
    )
  );

-- Professores podem ver horários das modalidades que lecionam
CREATE POLICY "Instructors can view schedules" ON class_schedules
  FOR SELECT USING (
    instructor_id IN (
      SELECT id FROM users WHERE firebase_uid = current_setting('request.jwt.claims')::json->>'sub'
    )
    OR
    modality_id IN (
      SELECT mt.modality_id FROM modality_teachers mt
      JOIN users u ON mt.user_id = u.id
      WHERE u.firebase_uid = current_setting('request.jwt.claims')::json->>'sub'
    )
  );

-- Membros aprovados podem ver horários ativos da academia
CREATE POLICY "Academy members can view active schedules" ON class_schedules
  FOR SELECT USING (
    is_active = TRUE
    AND academy_id IN (
      SELECT academy_id FROM academy_members 
      WHERE user_id IN (
        SELECT id FROM users WHERE firebase_uid = current_setting('request.jwt.claims')::json->>'sub'
      )
      AND status = 'approved'
    )
  );

