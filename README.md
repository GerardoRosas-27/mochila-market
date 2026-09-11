# MochilaMarket

App Flutter **multipuerto** (Android, iOS, Web, Desktop) en español para fotografiar mochilas, quitar el fondo, gestionar **inventario**, preparar publicaciones (borrador / feed de Página Meta), inbox con respuestas IA y datos de empresa.

**Repositorio:** https://github.com/GerardoRosas-27/mochila-market

## Características

- **Login local seguro:** primer usuario se registra; contraseña con **bcrypt** (nunca texto plano); sesión solo en el dispositivo; logout
- **Meta Graph API:** App ID, App Secret, token long-lived, Page ID, versión; validar token (`/me`, `debug_token`), listar páginas, publicar en feed de Página
- **Inventario de productos:** fotos, nombre, precio, descripción, SKU, stock, colores, tallas, material, marca, condición, tags, ubicación opcional · CRUD
- **Publicaciones desde inventario:** prefills fotos/campos; edición antes de guardar; post a Página vía Graph o borrador local
- **Datos de empresa:** nombre, dirección, lat/lng, croquis, horario por día (persistencia local)
- **Fotos / fondo / Inbox IA / Ajustes IA** (demo o APIs configurables)
- **Arquitectura:** Riverpod + go_router

## Limitación honesta: Facebook Marketplace

La API pública de Graph **no permite crear ítems de Facebook Marketplace** de forma general. La app:

- Publica en el **feed de tu Página** (`/{page-id}/feed`) cuando hay token + Page ID y permiso `pages_manage_posts`
- Guarda **borradores locales** / marca “listo”
- **No hace scraping** de Facebook

Algunos permisos de negocio requieren **App Review** en Meta.

## Login local

1. Al abrir la app por primera vez verás **Registrar y entrar**.
2. Elige usuario + contraseña (≥ 6 caracteres). Opcional: nombre para mostrar.
3. La contraseña se guarda solo como hash bcrypt en `flutter_secure_storage`.
4. En siguientes aperturas: pantalla de login. **Cerrar sesión** en Cuenta vuelve al gate.
5. Inventario, publicaciones, Meta y empresa quedan detrás de la sesión local.

## Configurar Meta Graph API

1. Ve a [developers.facebook.com](https://developers.facebook.com/) → crea una app (tipo Negocio / Consumidor según tu caso).
2. Añade el producto **Facebook Login** (o tokens de usuario) y genera un **User access token** con Graph API Explorer.
3. Permisos típicos:
   - Básicos / desarrollo: `public_profile`
   - Páginas: `pages_show_list`, `pages_read_engagement`, `pages_manage_posts` (este último suele requerir revisión para producción)
4. Intercambia a **long-lived token** (docs Meta: *Exchange Short-Lived Token*).
5. En la app: **Cuenta → Meta Graph API**
   - App ID (SharedPreferences)
   - App Secret (secure storage)
   - User / long-lived token (secure storage)
   - Page ID
   - Versión Graph (ej. `v21.0`)
6. Acciones: **Validar token**, **Listar páginas**, **Probar post Página**.

### Qué funciona vs App Review

| Capacidad | Estado típico |
|-----------|----------------|
| `GET /me` validar token | Funciona en modo desarrollo con token de admin/tester |
| `debug_token` | Requiere App ID + App Secret |
| `GET /me/accounts` listar páginas | Token con acceso a páginas |
| `POST /{page-id}/feed` | `pages_manage_posts` (review en prod) |
| Crear ítem Marketplace | **No disponible** vía API pública |

## Requisitos

- Flutter estable (3.24+)
- Dart SDK compatible
- Para APK Android: Android SDK + cmdline-tools

## Cómo ejecutar

```bash
export PATH="/workspace/flutter-sdk/bin:$PATH"   # si aplica
git clone https://github.com/GerardoRosas-27/mochila-market.git
cd mochila-market
flutter pub get
flutter run                 # dispositivo por defecto
flutter run -d chrome       # web
```

## APK

```bash
flutter build apk --release   # o --debug si falta keystore
# Artefacto típico: build/app/outputs/flutter-apk/app-release.apk
```

Copia empaquetada (cuando se genera en CI/box): `dist/mochila-market.apk` y `dist/mochila-market-apk.zip`.

## Estructura

```
lib/
  core/           # tema, router, storage, modelos
  features/
    auth/         # registro/login local (bcrypt)
    meta/         # Graph API config + cliente
    inventory/    # inventario rico (reemplaza catálogo fino)
    company/      # datos de empresa
    camera/       # captura + quitar fondo
    marketplace/  # borradores / post Página
    inbox/        # mensajes + IA
    account/      # sesión + enlaces a Meta/empresa/IA
    ai_settings/  # APIs imagen / multimodal / remove.bg
    home/         # shell NavigationBar
```

## Análisis

```bash
flutter analyze
```

Se permiten avisos informativos menores.

## Licencia

Uso del proyecto según el propietario del repositorio.
