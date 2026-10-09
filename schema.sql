-- Esquema Supabase (Postgres) para el dashboard de Compras Castilla Agrícola.
-- Ejecutar en el SQL Editor de Supabase (Project > SQL Editor > New query).

create table if not exists public.compras_detalle (
  id bigserial primary key,
  fecha date,
  nro_orden text,
  proveedor text,
  item text,
  referencia text,
  grupo_materiales text,      -- GRBI - BIENES / GRSE - SERVICIOS / GRPT - PLANTA DE MEZCLAS
  tipos_material text,        -- ICAM, REPU, MATE, ACFI, ADMO, SCMC, etc.
  area text,
  centro_costo text,
  estado text,                -- Cumplido / Anulado / Parcial / Aprobado / En proceso de aprobación
  valor_neto numeric,         -- Columna "Valor Bruto Compra Real" del histórico SIESA
  cantidad_pendiente numeric,
  empresa text not null default 'Castilla Agrícola'
);

create index if not exists idx_compras_fecha on public.compras_detalle (fecha);
create index if not exists idx_compras_tipos_material on public.compras_detalle (tipos_material);
create index if not exists idx_compras_grupo_materiales on public.compras_detalle (grupo_materiales);
create index if not exists idx_compras_estado on public.compras_detalle (estado);
create index if not exists idx_compras_empresa on public.compras_detalle (empresa);
create index if not exists idx_compras_proveedor on public.compras_detalle (proveedor);

-- Row Level Security: el dashboard se conecta con la clave pública "anon", así que debe poder
-- leer (SELECT) esta tabla. Ajusten la política según sus necesidades de seguridad interna.
alter table public.compras_detalle enable row level security;

create policy "Lectura pública de compras_detalle"
  on public.compras_detalle for select
  using (true);

-- No se habilita INSERT/UPDATE/DELETE para el rol anon: la carga de datos se hace por
-- importación de CSV (Table Editor > Import data) o por un proceso de backend con la
-- service_role key, nunca desde el navegador.

-- ---------------------------------------------------------------------------
-- Tablas para "Precios de mercado — Insumos" (Fertilización y Control Químico).
-- Hoy estos datos son pequeños y curados a mano; se modelan como tablas simples
-- para que a futuro se puedan actualizar sin tocar el código del dashboard.

create table if not exists public.insumos_fertilizacion (
  id bigserial primary key,
  mes smallint not null,            -- 0 = enero … 11 = diciembre
  anio smallint not null default 2026,
  precio_mezcla numeric,
  precio_urea numeric,
  precio_urea_recubierta numeric,
  precio_kcl numeric,
  proveedor text,
  cantidad numeric
);

create table if not exists public.insumos_control_quimico (
  id bigserial primary key,
  categoria text not null,          -- herbicida / fungicida / insecticida
  nombre text not null,
  codigo text,                      -- código "Referencia" del catálogo de materiales
  costo_catalogo numeric            -- último costo del catálogo (snapshot, respaldo si no hay compra real)
);

alter table public.insumos_fertilizacion enable row level security;
alter table public.insumos_control_quimico enable row level security;
create policy "Lectura pública insumos_fertilizacion" on public.insumos_fertilizacion for select using (true);
create policy "Lectura pública insumos_control_quimico" on public.insumos_control_quimico for select using (true);
