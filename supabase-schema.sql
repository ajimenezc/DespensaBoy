-- Script de configuración de Supabase para DespensaBoy
-- Ejecutar este script en el SQL Editor de Supabase después de crear el proyecto

-- Crear la tabla despensas
CREATE TABLE despensas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo TEXT UNIQUE NOT NULL,
  raciones JSONB DEFAULT '[]'::jsonb,
  historico JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índice para búsquedas rápidas por código
CREATE INDEX idx_despensas_codigo ON despensas(codigo);

-- Habilitar Row Level Security
ALTER TABLE despensas ENABLE ROW LEVEL SECURITY;

-- Política: Cualquiera puede leer
CREATE POLICY "Permitir lectura pública"
  ON despensas
  FOR SELECT
  USING (true);

-- Política: Cualquiera puede insertar
CREATE POLICY "Permitir inserción pública"
  ON despensas
  FOR INSERT
  WITH CHECK (true);

-- Política: Cualquiera puede actualizar
CREATE POLICY "Permitir actualización pública"
  ON despensas
  FOR UPDATE
  USING (true);

-- Habilitar Realtime para sincronización en tiempo real
ALTER PUBLICATION supabase_realtime ADD TABLE despensas;
