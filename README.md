# MochilaMarket

App Flutter **multipuerto** (Android, iOS, Web, Desktop) en español para fotografiar mochilas, quitar el fondo, preparar borradores de Marketplace, gestionar catálogo e inbox con respuestas IA.

**Repositorio:** https://github.com/GerardoRosas-27/mochila-market

## Características

- **Fotos:** cámara y galería (`camera`, `image_picker`)
- **Quitar fondo (pluggable):** proveedor **Demo** o **remove.bg** vía HTTP
- **Marketplace:** borradores de publicación (sin scraping de Meta)
- **Cuenta:** login demo con token en `flutter_secure_storage`
- **Ajustes IA:** API de imagen + multimodal; claves en almacenamiento seguro
- **Inbox:** respuestas IA (demo local o API chat/completions)
- **Catálogo:** CRUD con mochilas semilla
- **Arquitectura:** Riverpod + go_router, carpetas por feature

## Requisitos

- Flutter estable (3.24+)
- Dart SDK compatible

## Cómo ejecutar

```bash
# Clonar
git clone https://github.com/GerardoRosas-27/mochila-market.git
cd mochila-market

# Dependencias
flutter pub get

# Dispositivos
flutter devices

# Ejecutar (elige plataforma)
flutter run                 # dispositivo/emulador por defecto
flutter run -d chrome       # web
flutter run -d linux        # desktop Linux
flutter run -d macos        # macOS
flutter run -d windows      # Windows
```

## Configurar APIs (opcional)

1. Abre **Cuenta → Ajustes IA** (o el icono de afinación en Fotos).
2. Elige proveedor de fondo: **Demo** o **remove.bg** e ingresa la API key.
3. Para inbox con modelo real: Base URL estilo OpenAI (`…/v1`) + modelo multimodal + API key.
4. Las claves se guardan en **secure storage**; URLs/modelos en SharedPreferences.

Sin claves, la app usa flujos **demo** (fondo simulado y respuestas plantilla en español).

## Estructura

```
lib/
  core/           # tema, router, storage, modelos
  features/
    camera/       # captura / galería + quitar fondo
    bg_removal/   # contrato Demo + remove.bg HTTP
    marketplace/  # borradores
    catalog/      # CRUD mochilas
    inbox/        # mensajes + IA
    account/      # login demo seguro
    ai_settings/  # APIs imagen / multimodal / remove.bg
    home/         # shell con NavigationBar
```

## Análisis

```bash
flutter analyze
```

Se permiten avisos informativos menores.

## Licencia

Uso del proyecto según el propietario del repositorio.
