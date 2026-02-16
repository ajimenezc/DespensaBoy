-- Script de configuración SEGURA de Supabase para DespensaBoy
-- Ejecutar este script en el SQL Editor de Supabase

-- ============================================
-- PASO 1: Crear tabla (si no existe)
-- ============================================
CREATE TABLE IF NOT EXISTS despensas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT UNIQUE NOT NULL,
  raciones JSONB DEFAULT '[]'::jsonb,
  historico JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índice para búsquedas rápidas por código
CREATE INDEX IF NOT EXISTS idx_despensas_codigo ON despensas(codigo);

-- ============================================
-- PASO 2: Eliminar políticas antiguas inseguras
-- ============================================
DROP POLICY IF EXISTS "Permitir lectura pública" ON despensas;
DROP POLICY IF EXISTS "Permitir inserción pública" ON despensas;
DROP POLICY IF EXISTS "Permitir actualización pública" ON despensas;

-- ============================================
-- PASO 3: Habilitar Row Level Security
-- ============================================
ALTER TABLE despensas ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PASO 4: Nuevas políticas SEGURAS
-- ============================================

-- Política de LECTURA: Cualquiera puede leer (necesario para conectar con código)
CREATE POLICY "Permitir lectura SELECT"
  ON despensas
  FOR SELECT
  USING (true);

-- Política de INSERCIÓN: SOLO las Edge Functions (con SERVICE_ROLE_KEY)
-- La ANON_KEY NO puede insertar directamente
CREATE POLICY "Inserción solo desde Edge Functions"
  ON despensas
  FOR INSERT
  WITH CHECK (false); -- Bloqueado para ANON_KEY

-- Política de ACTUALIZACIÓN: SOLO las Edge Functions (con SERVICE_ROLE_KEY)
-- La ANON_KEY NO puede actualizar directamente
CREATE POLICY "Actualización solo desde Edge Functions"
  ON despensas
  FOR UPDATE
  USING (false); -- Bloqueado para ANON_KEY

-- Política de DELETE: BLOQUEADO (no hay funcionalidad de borrar despensas)
CREATE POLICY "No permitir DELETE"
  ON despensas
  FOR DELETE
  USING (false);

-- ============================================
-- PASO 5: Habilitar Realtime (opcional)
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE despensas;

-- ============================================
-- NOTAS IMPORTANTES
-- ============================================
-- Con estas políticas:
-- ✅ La ANON_KEY (pública en el frontend) puede LEER despensas
-- ❌ La ANON_KEY NO puede crear ni modificar despensas
-- ✅ Solo las Edge Functions (con SERVICE_ROLE_KEY privada) pueden escribir
-- ✅ Todas las operaciones de escritura están protegidas por Turnstile
-- ✅ Los atacantes no pueden hacer spam de despensas desde el frontend
