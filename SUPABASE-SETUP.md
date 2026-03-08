# 🗄️ Setup Completo do Supabase para Comando Zape

## 📋 Checklist de Implementação

### 1️⃣ Criar as Tabelas (SQL)
- [ ] Acessar: https://app.supabase.com
- [ ] Ir para **SQL Editor**
- [ ] Colar o conteúdo de `supabase-schema.sql` (arquivo neste diretório)
- [ ] Executar o SQL

### 2️⃣ Verificar as Tabelas Criadas
```
Supabase Dashboard → Table Editor
- [ ] closers (já existia)
- [ ] sdrs (já existia)
- [ ] origens (já existia)
- [ ] servicos (já existia)
- [x] movements (NOVO - acabou de criar)
- [x] movements_audit (NOVO - para auditoria)
```

### 3️⃣ Verificar RLS (Row Level Security)
- [ ] Ir para **Policies** na tabela `movements`
- [ ] Deve ter 4 policies automáticas:
  - ✅ Allow anon select
  - ✅ Allow anon insert
  - ✅ Allow anon update
  - ✅ Allow anon delete

### 4️⃣ Testar no Frontend

**Localização:** `/comando-zape/lancamentocomercial.html`

#### Teste 1: Registrar Movimento
```
1. Abrir: https://netonexus.github.io/comando-zape/
2. Ir para "Lançamento de Dados"
3. Preencher:
   - Closer: selecionar qualquer um
   - Data: hoje
   - Agendamentos: adicionar 1 SDR com quantidade
   - Reuniões: adicionar 1 SDR com quantidade
   - Ganho: clique "+ Registrar Ganho"
     - Origem: selecionar
     - Sub-origem: se houver
     - Serviço: selecionar
     - SDR: selecionar
     - Valor: 1500
   - Click "Registrar Movimentação"
4. Verificar:
   - ✅ Aparece na tabela "Histórico"
   - ✅ Console mostra "✅ Movement INSERT no Supabase"
```

#### Teste 2: Verificar no Supabase
```
1. Ir para Supabase Dashboard
2. Table Editor → movements
3. Deve ter 1 linha com:
   - data: "DD/MM/YYYY"
   - data_raw: "YYYY-MM-DD"
   - closer_id: (número)
   - agendamentos: [{"sdr_id": X, "quantidade": Y}]
   - reunioes: [{"sdr_id": X, "quantidade": Y}]
   - reagendamentos: []
   - noshows: []
   - ganhos: [{"origem_id": X, "origem_name": "...", ...}]
```

#### Teste 3: Editar Movimento
```
1. No Histórico, clique "Editar" em qualquer movimento
2. Modal abre
3. Mude a data ou reuniões
4. Clique "Salvar Alterações"
5. Verificar:
   - ✅ Tabela atualiza
   - ✅ Console mostra "✅ Movement UPDATE no Supabase"
   - ✅ Supabase Dashboard mostra dados atualizados
```

#### Teste 4: Deletar Movimento
```
1. No Histórico, clique "Deletar" em qualquer movimento
2. Confirme exclusão
3. Verificar:
   - ✅ Movimento sai da tabela
   - ✅ Console mostra "✅ Movement DELETE no Supabase"
   - ✅ Supabase Dashboard não tem mais a linha
```

#### Teste 5: Auto-Sync
```
1. Abrir Console (F12)
2. Registrar 3-4 movimentos rapidamente
3. Aguarde 30 segundos
4. Verificar:
   - ✅ Console mostra "[Auto-Sync] Verificando movimentos..."
   - ✅ Todos os movimentos estão no Supabase Dashboard
```

## 🔄 Como Funciona a Sincronização

### INSERT (Registrar Novo Movimento)
```javascript
registerMovement() → saveMovementToSupabase() → Supabase INSERT
```
- Acontece **imediatamente** ao clicar "Registrar Movimentação"
- Dados salvos em localStorage e Supabase simultaneamente

### UPDATE (Editar Movimento)
```javascript
saveEditMovement() → updateMovementInSupabase() → Supabase UPDATE
```
- Acontece **imediatamente** ao clicar "Salvar Alterações"
- Usa PATCH para atualizar apenas os campos modificados

### DELETE (Deletar Movimento)
```javascript
deleteMovement() → deleteMovementFromSupabase() → Supabase DELETE
```
- Acontece **imediatamente** ao confirmar exclusão

### Auto-Sync (A cada 30 segundos)
```javascript
setInterval(autoSyncToSupabase(), 30000)
```
- Verifica se há movimentos não sincronizados
- Tenta sincronizar automaticamente
- **Nunca duplica** dados (verifica se existe no Supabase antes)

## 📊 Estrutura de Dados

### Tabela: movements

```sql
id BIGSERIAL PRIMARY KEY
data TEXT                -- "08/03/2026" (DD/MM/YYYY)
data_raw DATE           -- "2026-03-08" (YYYY-MM-DD)
closer_id BIGINT        -- Referência a closers.id
agendamentos JSONB      -- [{"sdr_id": 1, "quantidade": 5}]
reunioes JSONB          -- [{"sdr_id": 1, "quantidade": 3}]
reagendamentos JSONB    -- [{"sdr_id": 2, "quantidade": 2}]
noshows JSONB           -- [{"sdr_id": 1, "quantidade": 1}]
ganhos JSONB            -- [{origem_id, origem_name, sub_origem, servico_id, servico_name, sdr_id, sdr_name, valor}]
created_at TIMESTAMP
updated_at TIMESTAMP
```

## 🚨 Troubleshooting

### Erro: "Cannot insert row - RLS policy violation"
**Solução:**
1. Ir para Policies na tabela `movements`
2. Adicionar policy "Allow anon insert":
   ```sql
   CREATE POLICY "Allow anon insert" ON movements FOR INSERT WITH CHECK (true);
   ```

### Erro: "Request failed with status 404"
**Solução:**
- Verificar se a tabela `movements` existe
- Verificar URL do Supabase no código

### Movimento registrado mas não aparece no Supabase
**Solução:**
1. Abrir Console (F12)
2. Procurar por "❌" ou "Movement INSERT"
3. Se tiver erro, ler a mensagem completa
4. Executar `loadMovementsFromSupabase()` no console para recarregar

### Console mostra muitas "auto-sync" mas nada muda
**Solução:**
- Isso é normal - sync acontece a cada 30 segundos
- Se há dados em localStorage mas não no Supabase, aguarde 30-60 segundos
- Ou recarregue a página (F5)

## ✅ Checklist Final

- [ ] SQL script executado no Supabase
- [ ] Tabelas visíveis no Table Editor
- [ ] RLS policies configuradas
- [ ] Teste 1 (Registrar): movimento aparece na tabela
- [ ] Teste 2 (Verificar): movimento está no Supabase
- [ ] Teste 3 (Editar): edição sincroniza
- [ ] Teste 4 (Deletar): exclusão sincroniza
- [ ] Teste 5 (Auto-Sync): auto-sync funciona
- [ ] Console sem erros vermelhos

## 📞 Suporte

Se algum teste falhar:
1. Abrir Console (F12)
2. Copiar a mensagem de erro
3. Passar para o Nexus com contexto do que estava fazendo

## 🎉 Parabéns!

Você agora tem uma **base de dados robusta e estruturada** com:
- ✅ CRUD completo (Create, Read, Update, Delete)
- ✅ Sincronização em tempo real
- ✅ Auditoria de mudanças
- ✅ Backup automático (localStorage + Supabase)
- ✅ Performance otimizada (índices, triggers)
