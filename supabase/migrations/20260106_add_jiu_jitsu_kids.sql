-- ============================================
-- MIGRATION: Adicionar Jiu-Jitsu Infantil, corrigir enum e remover default
-- Data: 2026-01-06
-- Descrição: 
--   1. Adiciona o tipo jiuJitsuKids ao enum martial_art_type
--   2. Corrige 'boxing' para 'boxe' (se existir)
--   3. Remove o DEFAULT 'jiuJitsu' da coluna martial_art_type (agora selecionado no cadastro)
-- ============================================

-- Adiciona novo valor ao enum martial_art_type
-- Nota: ALTER TYPE ... ADD VALUE não pode ser executado dentro de uma transaction
-- Por isso, este comando deve ser executado separadamente ou com COMMIT antes

ALTER TYPE martial_art_type ADD VALUE IF NOT EXISTS 'jiuJitsuKids' AFTER 'jiuJitsu';

-- Adiciona 'boxe' se não existir (para consistência com o Flutter)
ALTER TYPE martial_art_type ADD VALUE IF NOT EXISTS 'boxe';

-- Remove o DEFAULT da coluna martial_art_type (agora é obrigatório no cadastro)
ALTER TABLE users ALTER COLUMN martial_art_type DROP DEFAULT;

-- Comentário explicativo no enum
COMMENT ON TYPE martial_art_type IS 'Tipos de artes marciais disponíveis. jiuJitsuKids representa o sistema de graduação infantil do BJJ (4-15 anos)';

-- ============================================
-- NOTA: Se você precisa renomear 'boxing' para 'boxe' em dados existentes,
-- será necessário uma migração mais complexa:
-- 1. Criar novo enum com valores corretos
-- 2. Migrar dados das colunas
-- 3. Dropar enum antigo e renomear novo
-- 
-- Exemplo (executar manualmente se necessário):
-- 
-- -- Atualiza dados existentes
-- UPDATE users SET martial_art_type = 'boxe' WHERE martial_art_type = 'boxing';
-- UPDATE academy_modalities SET martial_art_type = 'boxe' WHERE martial_art_type = 'boxing';
-- -- etc para outras tabelas
-- ============================================

