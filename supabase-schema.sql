-- ============================================================
-- ESTRUTURA COMPLETA PARA COMANDO-ZAPE (Lancamento Comercial)
-- ============================================================

-- Tabela de Movimentações (Lançamentos Comerciais)
CREATE TABLE IF NOT EXISTS movements (
  id BIGSERIAL PRIMARY KEY,
  data TEXT NOT NULL,  -- DD/MM/YYYY para display
  data_raw DATE NOT NULL,  -- YYYY-MM-DD para filtro
  closer_id BIGINT NOT NULL REFERENCES closers(id) ON DELETE CASCADE,
  
  -- Arrays armazenados como JSON
  agendamentos JSONB DEFAULT '[]'::jsonb,  -- [{sdr_id, quantidade}, ...]
  reunioes JSONB DEFAULT '[]'::jsonb,      -- [{sdr_id, quantidade}, ...]
  reagendamentos JSONB DEFAULT '[]'::jsonb, -- [{sdr_id, quantidade}, ...]
  noshows JSONB DEFAULT '[]'::jsonb,       -- [{sdr_id, quantidade}, ...]
  ganhos JSONB DEFAULT '[]'::jsonb,        -- [{origem_id, origem_name, sub_origem, servico_id, servico_name, sdr_id, sdr_name, valor}, ...]
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_movements_closer_id ON movements(closer_id);
CREATE INDEX idx_movements_data_raw ON movements(data_raw);
CREATE INDEX idx_movements_created_at ON movements(created_at DESC);

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_movements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_movements_updated_at ON movements;
CREATE TRIGGER trigger_movements_updated_at
BEFORE UPDATE ON movements
FOR EACH ROW
EXECUTE FUNCTION update_movements_updated_at();

-- Tabela de auditoria (opcional - para histórico de mudanças)
CREATE TABLE IF NOT EXISTS movements_audit (
  id BIGSERIAL PRIMARY KEY,
  movement_id BIGINT NOT NULL REFERENCES movements(id) ON DELETE CASCADE,
  action TEXT NOT NULL,  -- 'INSERT', 'UPDATE', 'DELETE'
  old_data JSONB,
  new_data JSONB,
  changed_by TEXT DEFAULT 'system',
  changed_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_movements_audit_movement_id ON movements_audit(movement_id);
CREATE INDEX idx_movements_audit_changed_at ON movements_audit(changed_at DESC);

-- Função para auditoria
CREATE OR REPLACE FUNCTION audit_movements()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO movements_audit (movement_id, action, old_data)
    VALUES (OLD.id, 'DELETE', row_to_json(OLD));
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO movements_audit (movement_id, action, old_data, new_data)
    VALUES (NEW.id, 'UPDATE', row_to_json(OLD), row_to_json(NEW));
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO movements_audit (movement_id, action, new_data)
    VALUES (NEW.id, 'INSERT', row_to_json(NEW));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ⚠️ TRIGGER DESABILITADO - CAUSAVA FOREIGN KEY ERROR NO INSERT
-- DROP TRIGGER IF EXISTS trigger_audit_movements ON movements;
-- CREATE TRIGGER trigger_audit_movements
-- AFTER INSERT OR UPDATE OR DELETE ON movements
-- FOR EACH ROW
-- EXECUTE FUNCTION audit_movements();

-- ============================================================
-- Configurar RLS (Row Level Security) para acesso público
-- ============================================================

ALTER TABLE movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE movements_audit ENABLE ROW LEVEL SECURITY;

-- Policy: Anon pode ler tudo
CREATE POLICY "Allow anon select" ON movements FOR SELECT USING (true);
CREATE POLICY "Allow anon insert" ON movements FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon update" ON movements FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon delete" ON movements FOR DELETE USING (true);

CREATE POLICY "Allow anon audit select" ON movements_audit FOR SELECT USING (true);

-- ============================================================
-- Verificar se as tabelas de referência existem
-- ============================================================

-- closers
CREATE TABLE IF NOT EXISTS closers (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- sdrs
CREATE TABLE IF NOT EXISTS sdrs (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- origens
CREATE TABLE IF NOT EXISTS origens (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  sub_origem JSONB DEFAULT NULL,  -- Array de strings ou null
  created_at TIMESTAMP DEFAULT NOW()
);

-- servicos
CREATE TABLE IF NOT EXISTS servicos (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- Exemplo de INSERT para teste
-- ============================================================
-- Descomente para testar:

-- INSERT INTO closers (name) VALUES ('Closer 1') ON CONFLICT DO NOTHING;
-- INSERT INTO sdrs (name) VALUES ('SDR 1'), ('SDR 2') ON CONFLICT DO NOTHING;
-- INSERT INTO origens (name, sub_origem) VALUES 
--   ('Instagram', '["Instagram Neto", "Instagram Ads"]'::jsonb),
--   ('WhatsApp', NULL) ON CONFLICT DO NOTHING;
-- INSERT INTO servicos (name) VALUES ('Mentoria'), ('Consultoria'), ('Treinamento') ON CONFLICT DO NOTHING;

-- INSERT INTO movements (data, data_raw, closer_id, agendamentos, reunioes, reagendamentos, noshows, ganhos)
-- VALUES (
--   '08/03/2026',
--   '2026-03-08',
--   1,
--   '[{"sdr_id": 1, "quantidade": 5}]'::jsonb,
--   '[{"sdr_id": 1, "quantidade": 3}]'::jsonb,
--   '[{"sdr_id": 2, "quantidade": 2}]'::jsonb,
--   '[{"sdr_id": 1, "quantidade": 1}]'::jsonb,
--   '[{"origem_id": 1, "origem_name": "Instagram", "sub_origem": "Instagram Neto", "servico_id": 1, "servico_name": "Mentoria", "sdr_id": 1, "sdr_name": "SDR 1", "valor": 1500}]'::jsonb
-- );
