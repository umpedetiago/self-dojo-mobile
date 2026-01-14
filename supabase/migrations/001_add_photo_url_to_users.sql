-- Migration: Adicionar campo photo_url na tabela users
-- Data: 2026-01-09
-- Descrição: Garante que o campo photo_url existe na tabela users para armazenar URLs de fotos de perfil

-- Adiciona o campo photo_url se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'photo_url'
    ) THEN
        ALTER TABLE users ADD COLUMN photo_url TEXT;
        RAISE NOTICE 'Campo photo_url adicionado à tabela users';
    ELSE
        RAISE NOTICE 'Campo photo_url já existe na tabela users';
    END IF;
END $$;

-- Cria índice para melhorar performance de buscas por photo_url (opcional)
CREATE INDEX IF NOT EXISTS idx_users_photo_url ON users(photo_url) WHERE photo_url IS NOT NULL;

-- Comentário na coluna para documentação
COMMENT ON COLUMN users.photo_url IS 'URL da foto de perfil do usuário armazenada no Supabase Storage';

