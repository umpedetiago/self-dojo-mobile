-- ============================================
-- SELF DOJO - DATABASE SCHEMA
-- Supabase (PostgreSQL)
-- ============================================

-- Habilita extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ENUMS
-- ============================================

-- Tipos de artes marciais
CREATE TYPE martial_art_type AS ENUM (
  'jiuJitsu',
  'jiuJitsuKids',  -- Sistema de graduação infantil do BJJ (4-15 anos)
  'judo',
  'karate',
  'muayThai',
  'boxe',
  'taekwondo',
  'mma',
  'kickboxing'
);

-- Roles de usuário na academia
CREATE TYPE user_role AS ENUM (
  'student',
  'instructor',
  'teacher',
  'modalityMaster',
  'owner'
);

-- Status do membro na academia
CREATE TYPE academy_status AS ENUM (
  'pending',
  'approved',
  'suspended',
  'cancelled'
);

-- Status de pagamento
CREATE TYPE payment_status AS ENUM (
  'active',
  'pending',
  'overdue',
  'suspended',
  'exempt'
);

-- Tipo de plano de assinatura da academia
CREATE TYPE subscription_plan AS ENUM (
  'trial',
  'basic',
  'pro',
  'enterprise'
);

-- Tipo de plano do aluno
CREATE TYPE student_plan_type AS ENUM (
  'single',
  'duo',
  'full'
);

-- ============================================
-- TABELAS
-- ============================================

-- --------------------------------------------
-- USERS (complementa Firebase Auth)
-- --------------------------------------------
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid VARCHAR(128) UNIQUE NOT NULL, -- UID do Firebase Auth
  email VARCHAR(255) NOT NULL,
  display_name VARCHAR(100),
  photo_url TEXT,
  phone VARCHAR(20),
  
  -- Role global (pode ser diferente em cada academia)
  role user_role DEFAULT 'student',
  
  -- Campos para usuário sem academia (legado)
  martial_art_type martial_art_type,  -- Selecionado no cadastro
  legacy_belt_id VARCHAR(50),
  legacy_degree INTEGER DEFAULT 0,
  legacy_total_classes INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);

-- --------------------------------------------
-- ACADEMIES
-- --------------------------------------------
CREATE TABLE academies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  
  name VARCHAR(200) NOT NULL,
  description TEXT,
  logo_url TEXT,
  
  -- Localização
  address VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(50),
  country VARCHAR(50) DEFAULT 'Brasil',
  zip_code VARCHAR(20),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  
  -- Contato
  phone VARCHAR(20),
  email VARCHAR(255),
  website VARCHAR(255),
  
  -- Assinatura do app
  subscription_plan subscription_plan DEFAULT 'trial',
  subscription_started_at TIMESTAMPTZ,
  subscription_ends_at TIMESTAMPTZ,
  max_students INTEGER DEFAULT 10,
  max_teachers INTEGER DEFAULT 3,
  max_modalities INTEGER DEFAULT 3,
  
  -- Configuração financeira
  payment_due_day INTEGER DEFAULT 10,
  enrollment_fee DECIMAL(10, 2),
  annual_fee DECIMAL(10, 2),
  
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_academies_owner ON academies(owner_id);
CREATE INDEX idx_academies_city ON academies(city);

-- --------------------------------------------
-- ACADEMY_MODALITIES (modalidades por academia)
-- --------------------------------------------
CREATE TABLE academy_modalities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  academy_id UUID NOT NULL REFERENCES academies(id) ON DELETE CASCADE,
  martial_art_type martial_art_type NOT NULL,
  
  -- Mestre desta modalidade (pode ser null = owner gerencia)
  master_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Configuração de graduação
  use_default_graduation BOOLEAN DEFAULT TRUE,
  graduation_configured_by UUID REFERENCES users(id),
  graduation_updated_at TIMESTAMPTZ,
  
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(academy_id, martial_art_type)
);

CREATE INDEX idx_academy_modalities_academy ON academy_modalities(academy_id);

-- --------------------------------------------
-- BELT_CONFIGS (configuração de graduação personalizada)
-- --------------------------------------------
CREATE TABLE belt_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  modality_id UUID NOT NULL REFERENCES academy_modalities(id) ON DELETE CASCADE,
  
  belt_id VARCHAR(50) NOT NULL, -- Ex: 'white', 'blue_1', 'black_0'
  min_classes INTEGER DEFAULT 0,
  min_months INTEGER,
  min_classes_per_degree INTEGER,
  requires_exam BOOLEAN DEFAULT FALSE,
  exam_fee DECIMAL(10, 2),
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(modality_id, belt_id)
);

CREATE INDEX idx_belt_configs_modality ON belt_configs(modality_id);

-- --------------------------------------------
-- ACADEMY_MEMBERS (membros da academia)
-- --------------------------------------------
CREATE TABLE academy_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  academy_id UUID NOT NULL REFERENCES academies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  role user_role DEFAULT 'student',
  status academy_status DEFAULT 'pending',
  
  -- Para professores/instrutores
  managed_modalities martial_art_type[] DEFAULT '{}',
  
  -- Para alunos
  student_plan_id UUID,
  payment_status payment_status DEFAULT 'pending',
  payment_due_date DATE,
  
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  approved_at TIMESTAMPTZ,
  approved_by UUID REFERENCES users(id),
  
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(academy_id, user_id)
);

CREATE INDEX idx_academy_members_academy ON academy_members(academy_id);
CREATE INDEX idx_academy_members_user ON academy_members(user_id);
CREATE INDEX idx_academy_members_status ON academy_members(status);

-- --------------------------------------------
-- MODALITY_TEACHERS (professores por modalidade)
-- --------------------------------------------
CREATE TABLE modality_teachers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  modality_id UUID NOT NULL REFERENCES academy_modalities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role user_role NOT NULL CHECK (role IN ('teacher', 'instructor')),
  
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  assigned_by UUID REFERENCES users(id),
  
  UNIQUE(modality_id, user_id)
);

CREATE INDEX idx_modality_teachers_modality ON modality_teachers(modality_id);

-- --------------------------------------------
-- STUDENT_MODALITIES (matrículas em modalidades)
-- --------------------------------------------
CREATE TABLE student_modalities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id UUID NOT NULL REFERENCES academy_members(id) ON DELETE CASCADE,
  modality_id UUID NOT NULL REFERENCES academy_modalities(id) ON DELETE CASCADE,
  
  -- Professor responsável
  assigned_teacher_id UUID REFERENCES users(id),
  
  -- Graduação atual
  belt_id VARCHAR(50) NOT NULL,
  degree INTEGER DEFAULT 0,
  promotion_date TIMESTAMPTZ DEFAULT NOW(),
  classes_at_current_belt INTEGER DEFAULT 0,
  
  -- Estatísticas
  total_classes INTEGER DEFAULT 0,
  
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(member_id, modality_id)
);

CREATE INDEX idx_student_modalities_member ON student_modalities(member_id);
CREATE INDEX idx_student_modalities_modality ON student_modalities(modality_id);

-- --------------------------------------------
-- GRADUATION_HISTORY (histórico de graduações)
-- --------------------------------------------
CREATE TABLE graduation_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_modality_id UUID NOT NULL REFERENCES student_modalities(id) ON DELETE CASCADE,
  
  belt_id VARCHAR(50) NOT NULL,
  degree INTEGER DEFAULT 0,
  promoted_at TIMESTAMPTZ DEFAULT NOW(),
  promoted_by UUID REFERENCES users(id),
  
  classes_total INTEGER DEFAULT 0,
  exam_passed BOOLEAN,
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_graduation_history_student ON graduation_history(student_modality_id);

-- --------------------------------------------
-- STUDENT_PLANS (planos de mensalidade)
-- --------------------------------------------
CREATE TABLE student_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  academy_id UUID NOT NULL REFERENCES academies(id) ON DELETE CASCADE,
  
  name VARCHAR(100) NOT NULL,
  type student_plan_type NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  duration_months INTEGER DEFAULT 1,
  discount_percent DECIMAL(5, 2),
  
  included_modalities martial_art_type[],
  benefits TEXT[],
  
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_student_plans_academy ON student_plans(academy_id);

-- --------------------------------------------
-- CHECK_INS (para futuro sistema de check-in)
-- --------------------------------------------
CREATE TABLE check_ins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_modality_id UUID NOT NULL REFERENCES student_modalities(id) ON DELETE CASCADE,
  
  checked_in_at TIMESTAMPTZ DEFAULT NOW(),
  checked_in_by UUID REFERENCES users(id), -- NULL = self check-in
  
  -- Metadados
  class_type VARCHAR(50), -- 'regular', 'sparring', 'open_mat', etc
  duration_minutes INTEGER,
  notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_check_ins_student ON check_ins(student_modality_id);
CREATE INDEX idx_check_ins_date ON check_ins(checked_in_at);

-- ============================================
-- VIEWS
-- ============================================

-- View para buscar membro com detalhes completos
CREATE VIEW v_academy_members_full AS
SELECT 
  am.*,
  u.firebase_uid,
  u.email,
  u.display_name,
  u.photo_url,
  a.name as academy_name,
  sp.name as plan_name,
  sp.type as plan_type
FROM academy_members am
JOIN users u ON am.user_id = u.id
JOIN academies a ON am.academy_id = a.id
LEFT JOIN student_plans sp ON am.student_plan_id = sp.id;

-- View para buscar modalidades do aluno com detalhes
CREATE VIEW v_student_modalities_full AS
SELECT 
  sm.*,
  am.martial_art_type,
  am.academy_id,
  acm.user_id,
  u.display_name as student_name,
  t.display_name as teacher_name
FROM student_modalities sm
JOIN academy_modalities am ON sm.modality_id = am.id
JOIN academy_members acm ON sm.member_id = acm.id
JOIN users u ON acm.user_id = u.id
LEFT JOIN users t ON sm.assigned_teacher_id = t.id;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Atualiza updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER tr_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_academies_updated_at 
  BEFORE UPDATE ON academies 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_academy_modalities_updated_at 
  BEFORE UPDATE ON academy_modalities 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_academy_members_updated_at 
  BEFORE UPDATE ON academy_members 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_student_modalities_updated_at 
  BEFORE UPDATE ON student_modalities 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_student_plans_updated_at 
  BEFORE UPDATE ON student_plans 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- FUNCTION: Incrementar aulas do aluno
-- ============================================
CREATE OR REPLACE FUNCTION increment_student_classes(
  p_student_modality_id UUID
)
RETURNS VOID AS $$
BEGIN
  UPDATE student_modalities
  SET 
    total_classes = total_classes + 1,
    classes_at_current_belt = classes_at_current_belt + 1,
    updated_at = NOW()
  WHERE id = p_student_modality_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION: Promover aluno
-- ============================================
CREATE OR REPLACE FUNCTION promote_student(
  p_student_modality_id UUID,
  p_new_belt_id VARCHAR(50),
  p_degree INTEGER DEFAULT 0,
  p_promoted_by UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_current_classes INTEGER;
  v_last_belt_id VARCHAR(50);
  v_last_degree INTEGER;
BEGIN
  -- Pega classes atuais
  SELECT total_classes INTO v_current_classes
  FROM student_modalities WHERE id = p_student_modality_id;

  -- Verifica último registro de graduação para evitar duplicação
  SELECT belt_id, degree
  INTO v_last_belt_id, v_last_degree
  FROM graduation_history
  WHERE student_modality_id = p_student_modality_id
  ORDER BY promoted_at DESC, created_at DESC
  LIMIT 1;

  -- Se faixa e grau forem iguais ao último registro, não grava novo histórico nem atualiza graduação
  IF v_last_belt_id IS NOT NULL
     AND v_last_belt_id = p_new_belt_id
     AND v_last_degree = p_degree THEN
    RETURN;
  END IF;

  -- Registra no histórico
  INSERT INTO graduation_history (
    student_modality_id, belt_id, degree, promoted_by, classes_total, notes
  ) VALUES (
    p_student_modality_id, p_new_belt_id, p_degree, p_promoted_by, v_current_classes, p_notes
  );
  
  -- Atualiza graduação
  UPDATE student_modalities
  SET 
    belt_id = p_new_belt_id,
    degree = p_degree,
    promotion_date = NOW(),
    classes_at_current_belt = 0,
    updated_at = NOW()
  WHERE id = p_student_modality_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- RLS (Row Level Security) - IMPORTANTE!
-- ============================================

-- Habilita RLS em todas as tabelas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE academies ENABLE ROW LEVEL SECURITY;
ALTER TABLE academy_modalities ENABLE ROW LEVEL SECURITY;
ALTER TABLE belt_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE academy_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE modality_teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_modalities ENABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

-- POLICIES - Users
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (firebase_uid = current_setting('request.jwt.claims')::json->>'sub');

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (firebase_uid = current_setting('request.jwt.claims')::json->>'sub');

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (firebase_uid = current_setting('request.jwt.claims')::json->>'sub');

-- POLICIES - Academies (owners podem tudo, membros podem ver)
CREATE POLICY "Academy owners have full access" ON academies
  FOR ALL USING (
    owner_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.jwt.claims')::json->>'sub')
  );

CREATE POLICY "Academy members can view" ON academies
  FOR SELECT USING (
    id IN (
      SELECT academy_id FROM academy_members 
      WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.jwt.claims')::json->>'sub')
      AND status = 'approved'
    )
  );

-- POLICIES - Academy Members
CREATE POLICY "Members can view own membership" ON academy_members
  FOR SELECT USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = current_setting('request.jwt.claims')::json->>'sub')
  );

CREATE POLICY "Academy staff can manage members" ON academy_members
  FOR ALL USING (
    academy_id IN (
      SELECT id FROM academies WHERE owner_id IN (
        SELECT id FROM users WHERE firebase_uid = current_setting('request.jwt.claims')::json->>'sub'
      )
    )
  );

-- Nota: Adicione mais policies conforme necessário para cada tabela
-- Estas são apenas exemplos básicos para começar

-- ============================================
-- SEED DATA (opcional - dados iniciais)
-- ============================================

-- Isso pode ser executado separadamente se necessário

