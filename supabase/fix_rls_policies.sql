-- ============================================
-- FIX RLS POLICIES
-- Execute este script após o schema.sql
-- ============================================

-- Remove políticas antigas
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Academy owners have full access" ON academies;
DROP POLICY IF EXISTS "Academy members can view" ON academies;
DROP POLICY IF EXISTS "Members can view own membership" ON academy_members;
DROP POLICY IF EXISTS "Academy staff can manage members" ON academy_members;

-- ============================================
-- OPÇÃO 1: Desabilitar RLS (apenas para desenvolvimento)
-- ============================================
-- Descomente as linhas abaixo para desabilitar RLS completamente

ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE academies DISABLE ROW LEVEL SECURITY;
ALTER TABLE academy_modalities DISABLE ROW LEVEL SECURITY;
ALTER TABLE belt_configs DISABLE ROW LEVEL SECURITY;
ALTER TABLE academy_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE modality_teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_modalities DISABLE ROW LEVEL SECURITY;
ALTER TABLE graduation_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_plans DISABLE ROW LEVEL SECURITY;
ALTER TABLE check_ins DISABLE ROW LEVEL SECURITY;

-- ============================================
-- OPÇÃO 2: Políticas permissivas (para produção básica)
-- ============================================
-- Se preferir manter RLS habilitado, comente a OPÇÃO 1 acima
-- e descomente as linhas abaixo:

/*
-- Habilita RLS
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

-- Users: permite todas operações (validação feita no app)
CREATE POLICY "Allow all users operations" ON users FOR ALL USING (true) WITH CHECK (true);

-- Academies: permite todas operações
CREATE POLICY "Allow all academies operations" ON academies FOR ALL USING (true) WITH CHECK (true);

-- Academy Modalities
CREATE POLICY "Allow all modalities operations" ON academy_modalities FOR ALL USING (true) WITH CHECK (true);

-- Belt Configs
CREATE POLICY "Allow all belt_configs operations" ON belt_configs FOR ALL USING (true) WITH CHECK (true);

-- Academy Members
CREATE POLICY "Allow all members operations" ON academy_members FOR ALL USING (true) WITH CHECK (true);

-- Modality Teachers
CREATE POLICY "Allow all teachers operations" ON modality_teachers FOR ALL USING (true) WITH CHECK (true);

-- Student Modalities
CREATE POLICY "Allow all student_modalities operations" ON student_modalities FOR ALL USING (true) WITH CHECK (true);

-- Graduation History
CREATE POLICY "Allow all graduation_history operations" ON graduation_history FOR ALL USING (true) WITH CHECK (true);

-- Student Plans
CREATE POLICY "Allow all student_plans operations" ON student_plans FOR ALL USING (true) WITH CHECK (true);

-- Check-ins
CREATE POLICY "Allow all check_ins operations" ON check_ins FOR ALL USING (true) WITH CHECK (true);
*/

-- ============================================
-- Verifica status
-- ============================================
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

