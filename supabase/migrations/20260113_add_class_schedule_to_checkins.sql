-- Adiciona referência ao horário de aula no check-in
ALTER TABLE check_ins 
ADD COLUMN class_schedule_id UUID REFERENCES class_schedules(id) ON DELETE SET NULL;

-- Cria índice para melhorar performance
CREATE INDEX idx_check_ins_class_schedule ON check_ins(class_schedule_id);

-- Comentário explicativo
COMMENT ON COLUMN check_ins.class_schedule_id IS 'Referência ao horário de aula que o aluno fez check-in';

