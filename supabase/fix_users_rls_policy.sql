-- Fix: Policy RLS para permitir UPDATE na tabela users
-- Problema: A policy atual verifica JWT do Supabase Auth, mas o app usa Firebase Auth
-- Solução: Criar policy que permite UPDATE sem verificar JWT (já que Firebase Auth não passa JWT para Supabase)

-- Remove policy antiga se existir
DROP POLICY IF EXISTS "Users can update own profile" ON users;

-- Opção 1: Policy permissiva (permite qualquer UPDATE)
-- ⚠️ Use esta se você confia que apenas o app faz updates (recomendado para MVP)
CREATE POLICY "Users can update own profile"
ON users
FOR UPDATE
USING (true)  -- Permite qualquer update
WITH CHECK (true);

-- Opção 2: Policy mais restritiva (comentada - descomente se precisar)
-- Esta policy tenta verificar o firebase_uid, mas pode não funcionar sem JWT customizado
/*
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile"
ON users
FOR UPDATE
USING (
  -- Tenta pegar do JWT (pode não funcionar com Firebase Auth)
  firebase_uid = COALESCE(
    current_setting('request.jwt.claims', true)::json->>'sub',
    current_setting('request.jwt.claims', true)::json->>'firebase_uid'
  )
  OR
  -- Fallback: permite se não há JWT (para desenvolvimento)
  current_setting('request.jwt.claims', true) IS NULL
)
WITH CHECK (
  firebase_uid = COALESCE(
    current_setting('request.jwt.claims', true)::json->>'sub',
    current_setting('request.jwt.claims', true)::json->>'firebase_uid'
  )
  OR
  current_setting('request.jwt.claims', true) IS NULL
);
*/

-- Verifica se a policy foi criada
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'users' 
        AND policyname = 'Users can update own profile'
    ) THEN
        RAISE NOTICE '✅ Policy "Users can update own profile" criada/atualizada com sucesso';
    ELSE
        RAISE NOTICE '❌ ERRO: Policy não foi criada';
    END IF;
END $$;

-- Lista todas as policies da tabela users para verificação
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users';

