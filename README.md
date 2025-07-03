# Habbo Quick - Instalación Automatizada con Docker 🚀

Habbo Quick es un entorno Docker **completamente automatizado** para el [cliente Nitro](https://github.com/billsonnn/nitro-react) con [Arcturus Community Emulator](https://git.krews.org/morningstar/Arcturus-Community). 

**¡TODO automatizado! Sin configuración manual necesaria.**

## 🚀 Instalación Ultra-Rápida (Un Solo Comando)

```bash
docker compose up
```

¡Eso es todo! Con un solo comando tendrás todo el servidor de Habbo funcionando completamente automatizado.

> **💡 Nota importante**: Este proyecto está configurado para que **ningún archivo generado automáticamente** se suba al repositorio. Todo se descarga y configura localmente en tu máquina, manteniendo el repositorio limpio.

### Instalación Alternativa con Make

```bash
make install
```

## 📋 ¿Qué se automatiza?

✅ **Descarga automática de assets**: SWF pack, assets por defecto, room.nitro  
✅ **Descarga de assets actualizados**: Usando habbo-downloader con todos los assets de Habbo.com  
✅ **Conversión automática de gamedata**: XML/TXT → JSON automáticamente (figuredata, furnidata, productdata)  
✅ **Inicialización automática de base de datos**: Importa automáticamente todas las tablas necesarias  
✅ **Configuración automática**: Todos los settings del emulador y CMS  
✅ **Dependencias ordenadas**: Los servicios se inician en el orden correcto automáticamente  
✅ **Health checks avanzados**: Verificaciones de salud para asegurar que todo funcione  
✅ **Configuración automática del CMS**: Incluyendo generación de APP_KEY  
✅ **Backups automáticos**: Sistema de backup automático de la base de datos  
✅ **Conversión de assets**: Usando nitro-converter automáticamente  

## 🎯 Servicios Disponibles

| Servicio              | URL Local             | Descripción |
|-----------------------|-----------------------|-------------|
| 🎮 Nitro Client       | http://localhost:3000 | Cliente del juego |
| 📦 Assets Server      | http://localhost:8080 | Servidor de recursos |
| 🌐 CMS                | http://localhost:8081 | Panel de administración |
| 🗄️ Base de datos      | localhost:3310        | MySQL (usuario: arcturus_user, contraseña: arcturus_pw) |

## ⚡ Comandos Útiles

```bash
make help          # Ver todos los comandos disponibles
make start         # Iniciar servicios
make stop          # Parar servicios
make logs          # Ver logs en tiempo real
make clean         # Limpiar todo
make backup-db     # Hacer backup de la base de datos
make status        # Ver estado de servicios
make convert-gamedata  # Regenerar archivos JSON desde XML/TXT
make test-db       # Verificar base de datos
make fix-db        # Arreglar problemas de base de datos
make fix-db-force  # Reparación forzada de base de datos
```

## 🔧 Solución de Problemas

### Error db-initializer: "File './arcturus/emulator_settings.MYD' not found"

Este error indica que la tabla `emulator_settings` (MyISAM) está corrupta. **Solución rápida**:

```bash
# Opción 1: Script de emergencia automático
./emergency_fix.sh

# Opción 2: Comandos del Makefile
make fix-db-force

# Opción 3: Manual
make fix-db
```

**¿Qué hace la reparación?**
- ✅ Repara automáticamente tablas MyISAM corruptas
- ✅ Convierte a InnoDB si es necesario (más estable en Docker)
- ✅ Aplica todas las configuraciones necesarias
- ✅ Reinicia el inicializador automáticamente

## 🔧 Características Automatizadas

- ✅ **Descarga automática de assets**: SWF pack, assets por defecto, room.nitro
- ✅ **Descarga con habbo-downloader**: Assets actualizados de Habbo.com automáticamente
- ✅ **Conversión automática de gamedata**: figuredata.xml, furnidata.xml, productdata.txt → JSON automáticamente
- ✅ **Inicialización automática de base de datos**: Importa automáticamente todas las tablas necesarias
- ✅ **Configuración automática del emulador**: Todos los emulator_settings configurados automáticamente
- ✅ **Configuración automática del CMS**: Todos los website_settings configurados automáticamente
- ✅ **Generación automática de APP_KEY**: El CMS se configura completamente solo
- ✅ **Dependencias ordenadas**: Los servicios se inician en el orden correcto automáticamente
- ✅ **Health checks avanzados**: Verificaciones de salud para asegurar que todo funcione
- ✅ **Backups automáticos**: Sistema de backup automático de la base de datos
- ✅ **Conversión de assets**: Usando nitro-converter automáticamente
- ✅ **Conversión automática de gamedata**: XML/TXT → JSON con reparación automática de XML corrupto
- ✅ **Monitoreo automático**: Script de verificación de que todos los servicios funcionen

## 🐳 Arquitectura Docker

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nitro Client  │    │   Assets Server │    │      CMS        │
│   (Port 3000)   │    │   (Port 8080)   │    │   (Port 8081)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │  Arcturus Emu   │    │    MySQL DB     │    │   Imager Svc    │
    │   (Port 2096)   │    │   (Port 3310)   │    │   (Interno)     │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                 │
                       ┌─────────────────┐
                       │   Backup Svc    │
                       │   (Automático)  │
                       └─────────────────┘
```

## 🔄 Lo que se automatiza

Los assets y la base de datos se descargan e inicializan automáticamente solo la primera vez. En ejecuciones posteriores, el sistema detecta que ya existen y los omite para acelerar el proceso.

### Servicios de Inicialización (Una sola vez)
- **assets-downloader**: Descarga SWF pack, assets por defecto, assets de Habbo.com y convierte gamedata XML/TXT → JSON
- **db-initializer**: Configura la base de datos con todas las tablas y configuraciones
- **assets-builder**: Convierte assets usando nitro-converter

### Servicios Principales (Permanentes)
- **db**: Base de datos MySQL con health checks
- **backup**: Backups automáticos de la base de datos
- **arcturus**: Emulador con configuración automática
- **nitro**: Cliente web con configuración automática
- **assets**: Servidor de assets con nginx
- **imager**: Servicio de generación de imágenes
- **imgproxy**: Proxy de imágenes para optimización
- **cms**: AtomCMS con configuración completamente automática

## 🛠️ Configuración Avanzada

### Usando Traefik (Para producción)

```bash
make start-traefik
```

### Variables de entorno personalizadas

Edita `.env` después de ejecutar `make setup` para personalizar configuraciones.

### Comandos adicionales

```bash
make full-install      # Instalación completa + monitoreo automático
make quick-start       # Inicio rápido con docker compose
make monitor          # Verificar estado de todos los servicios
make force-rebuild    # Reconstruir todo desde cero
```

## 🐛 Solución de Problemas

### Ver logs específicos

```bash
make logs-arcturus    # Logs del emulador
make logs-nitro       # Logs del cliente
make logs-db          # Logs de la base de datos
```

### Monitorear servicios

```bash
make monitor          # Verificar que todos los servicios funcionen
make status           # Ver estado rápido de contenedores
```

### Limpiar y empezar de nuevo

```bash
make clean           # Limpiar contenedores e imágenes
make clean-data      # ⚠️ CUIDADO: Eliminar TODOS los datos
make force-rebuild   # Reconstruir todo completamente
```

## 🎉 ¡Disfruta tu servidor de Habbo!

Una vez que todo esté funcionando, podrás:

- 🎮 Jugar en <http://localhost:3000>
- 🌐 Administrar en <http://localhost:8081>
- 📦 Ver assets en <http://localhost:8080>
- 🗄️ Conectar a la DB en localhost:3310

**¿Problemas?** Abre un issue en GitHub o revisa los logs con `make logs`

## 📊 Características Técnicas

- **Docker Compose v3.8** con dependencias avanzadas
- **Health checks** en todos los servicios críticos
- **Multi-stage builds** para optimización de imagen
- **Volúmenes persistentes** para datos importantes
- **Redes aisladas** para seguridad
- **Backups automáticos** programados
- **Monitoreo de servicios** integrado
- **Configuración zero-touch** - sin intervención manual

## 📁 Estructura del Proyecto y Archivos Ignorados

Este proyecto está cuidadosamente configurado para mantener el repositorio **completamente limpio** de archivos generados automáticamente. Todo el contenido descargado, configuraciones generadas y datos persistentes se mantienen **solo localmente**.

### 🚫 Archivos que NUNCA se suben al repositorio (en .gitignore)

```text
# Configuraciones locales generadas automáticamente
.env                     # Variables de entorno locales  
.cms.env                 # Configuración específica del CMS
nitro/*.json             # Configuraciones de Nitro generadas

# Assets descargados automáticamente (varios GB)
assets/swf/              # SWF pack de Habbo.com
assets/assets/           # Assets por defecto del juego
assets/usercontent/      # Contenido generado por usuarios
assets/cache/            # Cache de assets convertidos
assets/bundled/          # Assets empaquetados

# Datos de base de datos (persistentes)
db/data/                 # Datos de MySQL
db/dumps/                # Dumps de base de datos
db/backup/               # Backups automáticos

# Logs y archivos temporales
logs/                    # Logs de todos los servicios
atomcms/logs/            # Logs específicos del CMS
atomcms/storage/         # Datos persistentes del CMS
atomcms/cache/           # Cache del CMS
*.log                    # Archivos de log individuales

# Backups y exportaciones
backups/                 # Backups de base de datos
export/                  # Exportaciones de contenedores
*.tar                    # Archivos de backup

# Archivos temporales del sistema
tmp/, temp/, .tmp/       # Directorios temporales
.DS_Store, Thumbs.db     # Archivos del sistema operativo
```

### ✅ Archivos importantes del repositorio (versionados)

```text
# Configuración principal de Docker
compose.yaml             # Configuración principal de Docker Compose
compose.dev.yaml         # Override para desarrollo con logs
compose.traefik.yaml     # Configuración con Traefik para producción

# Scripts de automatización
Makefile                 # Comandos útiles para el proyecto
setup.sh                 # Script principal de configuración
verify-gitignore.sh      # Verificación de que .gitignore funciona

# Plantillas y ejemplos
example-*.env            # Plantillas de configuración
nitro/example-*.json     # Plantillas de configuración de Nitro

# Scripts de inicialización
init/                    # Scripts de inicialización de servicios
├── download-assets.sh   # Descarga automática de assets
├── init-database.sh     # Inicialización de base de datos
├── monitor-services.sh  # Monitoreo de servicios
└── Dockerfile          # Contenedor de inicialización

# Configuración de servicios
arcturus/               # Configuración del emulador
├── Dockerfile         # Imagen del emulador
├── *.sql             # Scripts SQL del emulador
└── patches/          # Parches y hotfixes

atomcms/               # Configuración del CMS
├── Dockerfile        # Imagen del CMS
└── .gitkeep files    # Mantener estructura de directorios

nitro/                 # Configuración del cliente
├── Dockerfile        # Imagen del cliente
├── nginx.conf        # Configuración de nginx
└── example-*.json    # Plantillas de configuración

assets/                # Configuración del servidor de assets
├── Dockerfile        # Imagen del servidor de assets
├── nginx/           # Configuración de nginx
└── translation/     # Scripts de traducción y conversión
```

### 🧹 Comandos para mantener el repositorio limpio

```bash
# Verificar que .gitignore funciona correctamente
make check-gitignore

# Limpiar todos los archivos generados automáticamente
make clean-generated

# Ver estado del repositorio después de limpiar
make git-status

# Verificar completamente la limpieza del repositorio
make verify-repo-clean
```

### 🔍 ¿Por qué este enfoque?

1. **Repositorio liviano**: Sin assets pesados ni datos generados
2. **Colaboración limpia**: Solo código fuente y configuración versionados
3. **Setup consistente**: Cada desarrollador descarga assets frescos
4. **Sin conflictos**: No hay archivos generados que causen merge conflicts
5. **Actualizaciones automáticas**: Assets siempre actualizados de fuentes oficiales

## 🔧 Notas Técnicas Importantes

### Sistema de Permisos
Los permisos del emulador se generan automáticamente usando un archivo Excel (`perms.xlsx`) que contiene todas las configuraciones de permisos para diferentes rangos. El archivo SQL resultante (`perms_groups.sql`) ya está pre-generado y optimizado.

**Si necesitas regenerar los permisos:**
1. Modifica el archivo `arcturus/perms.xlsx`
2. Usa el script alternativo: `python3 perms_sql_openpyxl.py` (usa openpyxl en lugar de pandas)
3. O usa el script original: `python3 perms_sql.py` (requiere pandas instalado)

### Optimizaciones de Rendimiento
- **Assets pre-compilados**: Los assets se descargan y procesan una sola vez
- **Base de datos pre-configurada**: Todas las configuraciones se aplican automáticamente
- **Contenedores especializados**: Cada servicio tiene su propio contenedor optimizado
- **Health checks inteligentes**: Verificaciones de salud que aseguran la disponibilidad

## 🔧 Solución de Problemas Avanzada

### Error de Base de Datos (emulator_settings.MYD not found)

Si encuentras el error:
```
ERROR 29 (HY000): File './arcturus/emulator_settings.MYD' not found
```

**Solución rápida:**

```bash
make fix-db          # Arreglar problemas de base de datos
make test-db         # Verificar que todo funciona
```

**¿Qué hace `make fix-db`?**
- ✅ Reinicia el inicializador de base de datos
- ✅ Detecta y repara tablas MyISAM corruptas automáticamente
- ✅ Usa `INSERT ... ON DUPLICATE KEY UPDATE` para configuraciones robustas
- ✅ Verifica la integridad de tablas críticas

### Error de Archivos JSON Faltantes (FigureData.json, FurnitureData.json, etc.)

Si encuentras errores como:
```
GET /assets/gamedata/FigureData.json HTTP/1.1" 404 153
```

**Solución automática:**

```bash
make convert-gamedata    # Regenerar archivos JSON desde XML/TXT
```

**¿Qué hace `make convert-gamedata`?**
- ✅ Convierte automáticamente `figuredata.xml` → `FigureData.json`
- ✅ Convierte automáticamente `furnidata.xml` → `FurnitureData.json`  
- ✅ Convierte automáticamente `productdata.txt` → `ProductData.json`
- ✅ Se ejecuta automáticamente durante la instalación, pero puedes regenerarlo manualmente

**¿Por qué sucede esto?**
Los archivos JSON se generan automáticamente desde los archivos XML/TXT descargados de Habbo.com. En ocasiones estos archivos pueden faltar o corromperse.

### Diagnóstico Completo

```bash
make test-db         # Probar conexión y verificar tablas
make logs-db         # Ver logs de la base de datos
make status          # Ver estado de todos los servicios
```