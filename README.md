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

## Cómo ejecutar

```bash
export PATH="/workspace/flutter-sdk/bin:$PATH"
git clone https://github.com/GerardoRosas-27/mochila-market.git
cd mochila-market
flutter pub get
flutter run                 # móvil / desktop
flutter run -d chrome       # web (path URLs: /tienda, /p/…)
flutter build web --release --base-href /
```

## Descargas móviles (Android / iOS)

En Railway, Express sirve:

- `/downloads/mochila-market.apk`
- `/downloads/mochila-market-android.zip`
- `/downloads/mochila-market-ios.zip`

con `Content-Disposition: attachment`. El APK/ZIP se obtienen en el **Docker build** desde GitHub Releases (no se committean binarios grandes).

### Android APK

- Build local: `flutter build apk --release` (Android SDK + JDK).
- Release asset: tag `v1.2.0-mobile`, `MochilaMarket.apk` (también `MochilaMarket-android.zip`).
- Mirror Railway: `server/fetch_apk.sh` hace curl en la imagen Docker → `/downloads/mochila-market.apk` (+ ZIP con notas de instalación).

Fallbacks de fetch: `latest` → `v1.1.0-mobile` → `v1.0.0-mobile`.

### iOS (limitaciones)

Sin Mac/firma Apple **no** hay IPA instalable. El ZIP iOS es solo texto de instrucciones.

## Desplegar en Railway (web)

Despliegue **solo web** con Docker. Las carpetas `android/`, `ios/` y escritorio se mantienen en el repo; no se usan en el build de Railway (ver `.dockerignore`).

1. Entra a [Railway](https://railway.app) → **New Project** → **Deploy from GitHub repo**.
2. Autoriza GitHub si hace falta y selecciona **`GerardoRosas-27/mochila-market`**.
3. Railway detecta el `Dockerfile` (o `railway.toml` con builder `DOCKERFILE`), construye Flutter web y sirve con Express (estáticos + APK/ZIP en `/downloads/`).
4. Cuando termine el deploy, abre la URL pública del servicio (dominio `*.up.railway.app` o el que configures).
5. En la app (Cuenta), pega esa URL en **publicBaseUrl** (sin barra final).
6. Comparte enlaces `/tienda`, `/producto/:id` y `/p/:slug`.

**Base href:** en Railway se usa `--base-href /` (raíz del dominio).

Variables: Railway inyecta `PORT`; el contenedor ya escucha en `$PORT`. No hace falta configurar puerto a mano. Healthcheck: `/` (`railway.toml`).

```bash
# Build local equivalente al Dockerfile (web)
export PATH="/workspace/flutter-sdk/bin:$PATH"
flutter pub get
flutter build web --release --base-href /
# Runtime: node server/server.js con public/ = build/web y downloads/ vía fetch_apk.sh
```

## Análisis

```bash
flutter analyze
flutter build web --release --base-href /
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
Dockerfile       # flutter web → Express (public/ + /downloads/)
railway.toml     # DOCKERFILE builder, healthcheck /
server/
  server.js      # Express static + SPA fallback + APK/ZIP
  fetch_apk.sh   # curl APK desde GitHub Releases
  install_notes/ # INSTALL_ANDROID.txt / INSTALL_IOS.txt
```

## Almacenamiento

- **Móvil / desktop:** SQLite (`mochila_market.db`), migraciones v1→v3 (`slug`, `product_ids_json`).
- **Web:** SharedPreferences JSON (misma interfaz de repositorios).

## Licencia

Uso del proyecto según el propietario del repositorio.
