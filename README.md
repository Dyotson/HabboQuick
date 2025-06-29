# Habbo Quick - Instalación Automatizada con Docker 🚀

Habbo Quick es un entorno Docker **completamente automatizado** para el [cliente Nitro](https://github.com/billsonnn/nitro-react) con [Arcturus Community Emulator](https://git.krews.org/morningstar/Arcturus-Community). 

**¡TODO automatizado! Sin configuración manual necesaria.**

## 🚀 Instalación Ultra-Rápida (Un Solo Comando)

```bash
docker compose up
```

¡Eso es todo! Con un solo comando tendrás todo el servidor de Habbo funcionando completamente automatizado.

### Instalación Alternativa con Make

```bash
make install
```

## 📋 ¿Qué se automatiza?

✅ **Descarga automática de assets**: SWF pack, assets por defecto, room.nitro  
✅ **Descarga de assets actualizados**: Usando habbo-downloader con todos los assets de Habbo.com  
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
```

## 🔧 Características Automatizadas

- ✅ **Descarga automática de assets**: SWF pack, assets por defecto, room.nitro
- ✅ **Descarga con habbo-downloader**: Assets actualizados de Habbo.com automáticamente
- ✅ **Inicialización automática de base de datos**: Importa automáticamente todas las tablas necesarias
- ✅ **Configuración automática del emulador**: Todos los emulator_settings configurados automáticamente
- ✅ **Configuración automática del CMS**: Todos los website_settings configurados automáticamente
- ✅ **Generación automática de APP_KEY**: El CMS se configura completamente solo
- ✅ **Dependencias ordenadas**: Los servicios se inician en el orden correcto automáticamente
- ✅ **Health checks avanzados**: Verificaciones de salud para asegurar que todo funcione
- ✅ **Backups automáticos**: Sistema de backup automático de la base de datos
- ✅ **Conversión de assets**: Usando nitro-converter automáticamente
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
- **assets-downloader**: Descarga SWF pack, assets por defecto y assets de Habbo.com
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