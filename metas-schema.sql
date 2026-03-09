-- ============================================================
-- TABELA DE METAS MENSAIS (Acompanhamento de Meta)
-- ============================================================

-- Tabela principal de metas por mês
CREATE TABLE IF NOT EXISTS metas_mensais (
  id BIGSERIAL PRIMARY KEY,
  mes TEXT NOT NULL UNIQUE,  -- Formato: YYYY-MM (ex: 2026-03)
  nivel TEXT NOT NULL,  -- minima, super, ultra, black
  meta_mensal_vendas NUMERIC(15,2) NOT NULL,  -- Meta total de vendas do mês (R$)
  meta_diaria_vendas NUMERIC(15,2) NOT NULL,  -- Meta diária (calculada: meta_mensal / 22)
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de metas por Closer (mensal e diária)
CREATE TABLE IF NOT EXISTS metas_closers (
  id BIGSERIAL PRIMARY KEY,
  mes_id BIGINT NOT NULL REFERENCES metas_mensais(id) ON DELETE CASCADE,
  closer_id BIGINT NOT NULL REFERENCES closers(id) ON DELETE CASCADE,
  
  meta_mensal NUMERIC(15,2) NOT NULL DEFAULT 0,  -- Meta mensal em R$
  meta_diaria NUMERIC(15,2) NOT NULL DEFAULT 0,  -- Meta diária em R$ (calculada: meta_mensal / 22)
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(mes_id, closer_id)
);

-- Tabela de metas por SDR (mensal e diária - em agendamentos)
CREATE TABLE IF NOT EXISTS metas_sdrs (
  id BIGSERIAL PRIMARY KEY,
  mes_id BIGINT NOT NULL REFERENCES metas_mensais(id) ON DELETE CASCADE,
  sdr_id BIGINT NOT NULL REFERENCES sdrs(id) ON DELETE CASCADE,
  
  meta_mensal BIGINT NOT NULL DEFAULT 0,  -- Meta mensal em quantidade de agendamentos
  meta_diaria BIGINT NOT NULL DEFAULT 0,  -- Meta diária em quantidade (calculada: meta_mensal / 22)
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(mes_id, sdr_id)
);

-- ============================================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================================

CREATE INDEX idx_metas_mensais_mes ON metas_mensais(mes DESC);
CREATE INDEX idx_metas_closers_mes_id ON metas_closers(mes_id);
CREATE INDEX idx_metas_closers_closer_id ON metas_closers(closer_id);
CREATE INDEX idx_metas_sdrs_mes_id ON metas_sdrs(mes_id);
CREATE INDEX idx_metas_sdrs_sdr_id ON metas_sdrs(sdr_id);

-- ============================================================
-- TRIGGERS PARA ATUALIZAR updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_metas_mensais_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_metas_mensais_updated_at ON metas_mensais;
CREATE TRIGGER trigger_metas_mensais_updated_at
BEFORE UPDATE ON metas_mensais
FOR EACH ROW
EXECUTE FUNCTION update_metas_mensais_updated_at();

CREATE OR REPLACE FUNCTION update_metas_closers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_metas_closers_updated_at ON metas_closers;
CREATE TRIGGER trigger_metas_closers_updated_at
BEFORE UPDATE ON metas_closers
FOR EACH ROW
EXECUTE FUNCTION update_metas_closers_updated_at();

CREATE OR REPLACE FUNCTION update_metas_sdrs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_metas_sdrs_updated_at ON metas_sdrs;
CREATE TRIGGER trigger_metas_sdrs_updated_at
BEFORE UPDATE ON metas_sdrs
FOR EACH ROW
EXECUTE FUNCTION update_metas_sdrs_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE metas_mensais ENABLE ROW LEVEL SECURITY;
ALTER TABLE metas_closers ENABLE ROW LEVEL SECURITY;
ALTER TABLE metas_sdrs ENABLE ROW LEVEL SECURITY;

-- Policy: Anon pode ler tudo
CREATE POLICY "Allow anon select" ON metas_mensais FOR SELECT USING (true);
CREATE POLICY "Allow anon insert" ON metas_mensais FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon update" ON metas_mensais FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon delete" ON metas_mensais FOR DELETE USING (true);

CREATE POLICY "Allow anon select" ON metas_closers FOR SELECT USING (true);
CREATE POLICY "Allow anon insert" ON metas_closers FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon update" ON metas_closers FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon delete" ON metas_closers FOR DELETE USING (true);

CREATE POLICY "Allow anon select" ON metas_sdrs FOR SELECT USING (true);
CREATE POLICY "Allow anon insert" ON metas_sdrs FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow anon update" ON metas_sdrs FOR UPDATE USING (true) WITH CHECK (true);
CREATE POLICY "Allow anon delete" ON metas_sdrs FOR DELETE USING (true);

-- ============================================================
-- EXEMPLO DE INSERT PARA TESTE (descomente se quiser testar)
-- ============================================================

-- INSERT INTO metas_mensais (mes, nivel, meta_mensal_vendas, meta_diaria_vendas)
-- VALUES ('2026-03', 'ultra', 50000, 2273) ON CONFLICT DO NOTHING;

-- SELECT * FROM metas_mensais;
