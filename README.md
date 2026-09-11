# MochilaMarket

App Flutter **multipuerto** (Android, iOS, Web, Desktop) en español para fotografiar mochilas, quitar el fondo con **API externa**, gestionar **inventario local (SQLite / web prefs)** y publicar **grupos de ofertas** con URL pública para compartir en Marketplace.

**La app no publica a Facebook ni usa Meta Graph API.** «Exportar como borrador» copia el texto de plantilla al portapapeles.

**Repositorio:** https://github.com/GerardoRosas-27/mochila-market

## Modelo de producto (v1.2)

| Concepto | Qué es | Ruta |
|----------|--------|------|
| **Tienda** | Catálogo público de **todas** las mochilas disponibles del inventario (`available` + stock) | `/tienda` |
| **Producto** | Detalle de inventario: precio + características | `/producto/:id` |
| **Publicación** | **Grupo de ofertas**: uno o más productos del inventario empaquetados | `/p/:slug` (alias `/oferta/:slug`) |

- Crear publicación = seleccionar/agrupar productos del inventario.
- Cada publicación tiene **slug estable** y URL pública (`publicBaseUrl` + `/p/slug`) para pegar en respuestas de Marketplace.
- **Exportar como borrador** = plantilla Marketplace → portapapeles (no es estado «no publicado»).

Rutas admin (login local): `/publicaciones`, `/inventario`, `/fotos`, `/inbox`, `/cuenta`.

## URL scheme

```
/tienda                 → storefront (público)
/producto/:id           → detalle inventario (público)
/p/:slug                → detalle publicación / oferta (público)
/oferta/:slug           → redirect → /p/:slug
/publicaciones          → admin grupos de ofertas (auth)
/inventario             → CRUD productos (auth)
/login                  → auth local bcrypt
```

Enlace compartible: `{publicBaseUrl}/p/{slug}`  
Ejemplo: `https://tu-app.up.railway.app/p/pack-urbanas-a1b2c3d4`

Configura **Cuenta → URL pública (Railway)**.

## Características

- **Login local seguro:** primer usuario se registra; contraseña con **bcrypt**; sesión solo en el dispositivo
- **Inventario CRUD:** fotos, nombre, precio, descripción, SKU, stock, colores, tallas, material, marca, condición, tags
- **Publicaciones (grupos de ofertas):** selección múltiple de productos + fotos/grupos; slug; exportar borrador Marketplace
- **Plantilla Marketplace configurable** con placeholders
- **IA externa pluggable** (quitar fondo, inbox)
- **Arquitectura:** Riverpod + go_router + repositorios (SQLite móvil/desktop; SharedPreferences en web)

## Despliegue en Railway (Flutter web)

1. Conecta el repo en Railway (o `railway up` con este `Dockerfile`).
2. Railway construye la imagen multi-stage (Flutter → nginx).
3. El contenedor sirve `build/web` con **SPA fallback** (`nginx.conf` → `try_files … /index.html`) para deep links.
4. Anota la URL pública (ej. `https://mochila-market-production.up.railway.app`).
5. En la app (Cuenta), pega esa URL en **publicBaseUrl** (sin barra final).
6. Comparte enlaces `/tienda`, `/producto/:id` y `/p/:slug`.

Variables opcionales: ninguna obligatoria; la URL se guarda en el cliente (`SharedPreferences`).

```bash
# Build local equivalente al Dockerfile
export PATH="/workspace/flutter-sdk/bin:$PATH"
flutter pub get
flutter build web --release
# Sirve build/web con cualquier static server que haga fallback a index.html
```

## Cómo ejecutar

```bash
export PATH="/workspace/flutter-sdk/bin:$PATH"
git clone https://github.com/GerardoRosas-27/mochila-market.git
cd mochila-market
flutter pub get
flutter run                 # móvil / desktop
flutter run -d chrome       # web (path URLs: /tienda, /p/…)
```

## APK

```bash
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Artefactos: `dist/MochilaMarket.apk` y `dist/MochilaMarket-android.zip`.

## Análisis

```bash
flutter analyze
flutter build web --release
```

## Estructura

```
lib/
  core/          # modelos, router, SQLite/prefs, slug, publicBaseUrl
  features/
    storefront/  # /tienda, /producto/:id, /p/:slug
    marketplace/ # admin Publicaciones (grupos de ofertas)
    inventory/   # CRUD
    auth/ camera/ inbox/ template/ company/ …
Dockerfile       # flutter build web → nginx SPA
nginx.conf       # deep-link fallback
```

## Almacenamiento

- **Móvil / desktop:** SQLite (`mochila_market.db`), migraciones v1→v3 (`slug`, `product_ids_json`).
- **Web:** SharedPreferences JSON (misma interfaz de repositorios).

## Licencia

Uso del proyecto según el propietario del repositorio.
