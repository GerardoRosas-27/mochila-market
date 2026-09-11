# MochilaMarket

App Flutter **multipuerto** (Android, iOS, Web, Desktop) en español para fotografiar mochilas, quitar el fondo con **API externa**, gestionar **inventario local (SQLite)** y preparar **borradores de Marketplace** con plantilla configurable y grupos de fotos.

**La app no publica a Facebook ni usa Meta Graph API.** Copia el texto del borrador y pégalo en Marketplace u otro canal.

**Repositorio:** https://github.com/GerardoRosas-27/mochila-market

## Características

- **Login local seguro:** primer usuario se registra; contraseña con **bcrypt**; sesión solo en el dispositivo
- **Inventario CRUD (SQLite):** fotos, nombre, precio, descripción, SKU, stock, colores, tallas, material, marca, condición, tags, ubicación
- **Borradores de publicación:** desde inventario (aplica plantilla) o manual; estados borrador / listo / publicado-local
- **Plantilla Marketplace configurable:** título y cuerpo con placeholders (`{{nombre}}`, `{{precio}}`, `{{descripcion}}`, `{{direccion}}`, …) en **Cuenta → Plantilla Marketplace**
- **Grupos de fotos:** varias imágenes asociadas a un borrador (grupo reutilizable)
- **Datos de empresa:** nombre, dirección, lat/lng, croquis, horario (alimentan defaults de plantilla)
- **IA externa pluggable:** base URL + API key + model id (imagen / multimodal); quitar fondo: demo, remove.bg u HTTP genérico
- **Arquitectura:** Riverpod + go_router + repositorios (SQLite ahora, Postgres después)

## Plantillas

En **Cuenta → Plantilla Marketplace** editas:

- **Título** (ej. `{{nombre}} — {{marca}} · ${{precio}}`)
- **Cuerpo** (descripción, specs, dirección, horario…)

Al crear un borrador **desde inventario**, `MarketplaceTemplateRenderer` sustituye los placeholders con el producto y los datos de empresa.

Placeholders: `{{nombre}}` `{{precio}}` `{{descripcion}}` `{{sku}}` `{{stock}}` `{{colores}}` `{{tallas}}` `{{material}}` `{{marca}}` `{{condicion}}` `{{etiquetas}}` `{{direccion}}` `{{empresa}}` `{{horario}}` `{{ubicacion}}`

## Grupos de fotos

1. En **Borradores**, icono de galería → crear grupo (nombre + varias fotos).
2. Al crear/editar un borrador, elige un grupo opcional o añade fotos sueltas.
3. El borrador guarda `photo_group_id` y/o `image_paths`; la UI muestra la unión de ambas.

## Login local

1. Primera apertura: **Registrar y entrar** (usuario + contraseña ≥ 6).
2. Hash bcrypt en `flutter_secure_storage`.
3. **Cerrar sesión** en Cuenta vuelve al gate.

## Ajustes IA (API externa)

**Cuenta → Ajustes IA**:

| Campo | Uso |
|-------|-----|
| Base URL / model id / API key imagen | Captions / fondo genérico |
| Base URL / model / key multimodal | Respuestas inbox |
| Proveedor fondo | `demo` · `remove.bg` · `HTTP genérico` |

Las claves van a secure storage; URLs/modelos a SharedPreferences (públicos).

## Requisitos

- Flutter estable (3.24+)
- Para APK Android: Android SDK + cmdline-tools

## Cómo ejecutar

```bash
export PATH="/workspace/flutter-sdk/bin:$PATH"   # si aplica
git clone https://github.com/GerardoRosas-27/mochila-market.git
cd mochila-market
flutter pub get
flutter run
flutter run -d chrome
```

## APK

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Artefactos empaquetados (cuando se generan): `dist/MochilaMarket.apk` y `dist/MochilaMarket-android.zip`.

## Estructura

```
lib/
  core/
    data/
      database/       # AppDatabase (sqflite)
      repositories/   # interfaces
      sqlite/         # implementaciones locales
      cloud/          # CloudRepository stub (Postgres futuro)
    models/
    router/ theme/ storage/ widgets/
  features/
    auth/             # login local bcrypt
    inventory/        # CRUD productos
    marketplace/      # borradores
    template/         # plantilla + renderer
    photo_groups/     # grupos de fotos
    company/          # datos empresa
    camera/           # captura + quitar fondo
    inbox/            # mensajes + IA
    ai_settings/      # APIs externas
    account/ home/
```

## Almacenamiento: SQLite → Postgres (migración futura)

Persistencia actual: archivo `mochila_market.db` (sqflite).

Interfaces en `lib/core/data/repositories/`; implementaciones SQLite en `lib/core/data/sqlite/`. El stub `CloudRepository` (`lib/core/data/cloud/cloud_repository_stub.dart`) documenta el punto de enganche remoto (aún no operativo).

### Mapeo de esquema

| SQLite | Postgres (propuesto) | Notas |
|--------|----------------------|-------|
| `products` | `products` | `colors_json`/`sizes_json`/`tags_json`/`photo_paths_json` → `JSONB` o arrays `TEXT[]` |
| `listing_drafts` | `listing_drafts` | `image_paths_json` → `JSONB`; FK opcional `product_id`, `photo_group_id` |
| `photo_groups` | `photo_groups` | `photo_paths_json` → `JSONB` |
| `marketplace_template` (fila id=1) | `marketplace_templates` | Una fila activa por tenant; o tabla con `is_default` |
| `company_data` (payload_json) | `companies` | Columnas tipadas + `hours JSONB` |
| `app_settings` | `app_settings` | key/value por usuario/tenant |

Tipos sugeridos Postgres:

- IDs: `UUID PRIMARY KEY` (hoy TEXT UUID en SQLite)
- Precios: `NUMERIC(12,2)`
- Booleanos: `BOOLEAN` (SQLite usa INTEGER 0/1)
- Timestamps: `TIMESTAMPTZ` (`created_at` ISO-8601 en SQLite)

Pasos de migración típicos:

1. Implementar repositorios Postgres detrás de las mismas interfaces.
2. Exportar SQLite → CSV/JSON → `COPY` / upsert.
3. Subir fotos a object storage y reemplazar paths locales por URLs.
4. Activar `CloudRepository` / cambiar providers Riverpod.

## Análisis

```bash
flutter analyze
```

## Licencia

Uso del proyecto según el propietario del repositorio.
