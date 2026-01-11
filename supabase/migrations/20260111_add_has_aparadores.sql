-- Adiciona coluna para armazenar se o usuário tem aparadores na faixa preta
-- Relevante apenas quando degree = 0, pois com graus os aparadores são padrão

ALTER TABLE users ADD COLUMN IF NOT EXISTS legacy_has_aparadores BOOLEAN;

COMMENT ON COLUMN users.legacy_has_aparadores IS 'Se tem aparadores na faixa preta (relevante apenas quando degree = 0)';

