# Dashboard de Compras — Castilla Agrícola · Migración a Supabase + GitHub

Este paquete contiene todo lo necesario para alojar el dashboard de compras en infraestructura propia
de la empresa (servidor interno) en vez del link privado de Claude.

## Qué hay en esta carpeta

| Archivo | Para qué sirve |
|---|---|
| `schema.sql` | Esquema de base de datos (Postgres) para Supabase. Crea la tabla `compras_detalle` y dos tablas auxiliares para la sección de precios de insumos. |
| `compras_detalle.csv` | Las 36.911 líneas de órdenes de compra (histórico SIESA, columna "Valor Bruto Compra Real"), listas para importar. |
| `dashboard-supabase.html` | El dashboard, modificado para leer los datos desde Supabase en vez de un archivo JSON estático. |
| `README-TI.md` | Este archivo. |

## Paso 1 — Crear el proyecto en Supabase

1. Crear una cuenta/organización en [supabase.com](https://supabase.com) si no existe.
2. Crear un nuevo proyecto (anota la contraseña de la base de datos que te pidan).
3. Ir a **SQL Editor > New query**, pegar el contenido de `schema.sql` y ejecutarlo.
   Esto crea `compras_detalle`, `insumos_fertilizacion`, `insumos_control_quimico` y sus políticas
   de seguridad (solo lectura pública vía la clave `anon`, sin escritura desde el navegador).

## Paso 2 — Cargar los datos

1. Ir a **Table Editor > compras_detalle > Insert > Import data from CSV**.
2. Subir `compras_detalle.csv`. Confirmar que las columnas coincidan (deberían mapearse automáticamente
   por nombre: `fecha, nro_orden, proveedor, item, referencia, grupo_materiales, tipos_material, area,
   centro_costo, estado, valor_neto, cantidad_pendiente, empresa`).
3. La importación son ~36.900 filas; Supabase la procesa en un par de minutos.
4. (Opcional, pendiente) Cargar manualmente las ~11 filas de `insumos_fertilizacion` y los ~18 ítems de
   `insumos_control_quimico` — hoy esos datos están embebidos directamente en el HTML del dashboard
   (sección "Precios de mercado — Insumos"); si se quiere que también vengan de Supabase, hay que
   extraerlos del HTML y cargarlos a esas tablas, y adaptar esa sección del script para leerlas (no
   está hecho en esta primera entrega: toma menos de una hora pero no era parte del alcance pedido).

## Paso 3 — Conectar el dashboard a Supabase

1. En Supabase: **Project Settings > API**. Copiar el **Project URL** y la clave **anon public**.
2. Abrir `dashboard-supabase.html` en un editor de texto y buscar estas dos líneas (cerca del final
   del archivo, dentro de `<script>`):
   ```js
   var SUPABASE_URL = 'https://TU-PROYECTO.supabase.co';
   var SUPABASE_ANON_KEY = 'TU-ANON-KEY-AQUI';
   ```
   Reemplazar por los valores reales del proyecto.
3. La clave `anon` es segura para dejar visible en el HTML: la tabla solo permite `SELECT` para ese
   rol (ver la política `Lectura pública` en `schema.sql`), no permite insertar, modificar ni borrar.

## Paso 4 — Subir a GitHub

```bash
git init
git add dashboard-supabase.html schema.sql README-TI.md
git commit -m "Dashboard de compras Castilla Agrícola - versión Supabase"
git remote add origin <URL-del-repo-que-cree-TI>
git push -u origin main
```

No se incluye `compras_detalle.csv` en el repo (ya está cargado en Supabase, y son 7MB de datos que
no necesitan vivir en control de versiones).

## Paso 5 — Publicarlo en el servidor de la empresa

`dashboard-supabase.html` es un archivo único, sin dependencias de backend (todo el cálculo pasa en
el navegador, igual que la versión actual). Para servirlo basta con:
- Copiarlo a cualquier servidor web estático (IIS, Nginx, Apache, o incluso un bucket S3/Azure Blob
  con hosting estático), **o**
- Usar GitHub Pages sobre el mismo repo (Settings > Pages > Deploy from branch).

No requiere Node, build step, ni servidor de aplicación — es HTML/CSS/JS puro que llama a la API REST
de Supabase directamente desde el navegador del usuario.

## Actualizar los datos a futuro

Cuando haya una nueva descarga de SIESA:
1. Volver a generar el CSV con el mismo formato de columnas que `compras_detalle.csv`.
2. En Supabase: `TRUNCATE TABLE compras_detalle;` y volver a importar el CSV nuevo
   (o hacer un `UPSERT` si se quiere evitar borrar y recargar todo — requiere definir una
   clave única, por ejemplo `nro_orden + referencia + fecha`, que hoy no existe como constraint).
3. El dashboard no necesita cambios: al recargar la página trae los datos actualizados de Supabase.

## Qué NO se migró en esta entrega

- La sección "Precios de mercado — Insumos" sigue con datos embebidos en el HTML (ver Paso 2,
  punto 4) — son datos pequeños, curados a mano desde dos archivos Excel distintos
  ("Formulacion Mezcla Especial UREA + KCL Angela.xlsx" y "1. Proyección de Núcleos - Materiales.xlsx"),
  no hacían parte del alcance original de "migrar el dashboard de compras".
- No se configuró autenticación (login): el dashboard queda de **lectura pública** para quien tenga
  la URL donde IT lo publique. Si se necesita restringir el acceso, hay que agregar autenticación
  (Supabase Auth + cambiar la política RLS de `using (true)` a `using (auth.role() = 'authenticated')`,
  o protegerlo a nivel de red/VPN en el servidor donde se publique) — no implementado aquí.
