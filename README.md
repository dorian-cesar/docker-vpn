# Servidor VPN WireGuard en AWS Lightsail con Docker

Este proyecto te permite desplegar un servidor VPN **WireGuard** con interfaz web de administración (**wg-easy**) en una instancia de **AWS Lightsail** de forma rápida y automatizada.

---

## 📋 Requisitos Previos en AWS Lightsail

Antes de instalar la VPN, debes realizar 2 pasos sencillos en la consola web de AWS Lightsail:

### 1. Asignar una IP Estática Pública (Static IP)
1. Ve a la consola de **AWS Lightsail** > pestaña **Redes (Networking)**.
2. Haz clic en **Crear IP estática (Create static IP)** y adhiérela a tu instancia.
   *(Esto evita que la IP cambie cada vez que la instancia se reinicie).*

### 2. Configurar el Firewall de Lightsail (Reglas de entrada)
1. Entra a tu instancia en Lightsail > pestaña **Redes (Networking)** > sección **Firewall**.
2. Agrega las siguientes **2 reglas de entrada**:

| Protocolo | Rango de Puertos | Propósito |
| :--- | :--- | :--- |
| **UDP** | `51820` | Tráfico del túnel VPN WireGuard |
| **TCP** | `51821` | Acceso al Panel de Administración (Web UI) |

---

## 🚀 Instalación Rápida (1 solo paso)

### Opción A: Mediante el Script de Instalación Automatizada

1. Conéctate a tu instancia de Lightsail mediante **SSH** (puedes usar el botón "Conectarse mediante SSH" en la consola de AWS o un terminal local).
2. Clona o sube estos archivos a la instancia.
3. Ejecuta el script de instalación automatizada con permisos `sudo`:

```bash
sudo bash install-lightsail.sh
```

El script se encargará automáticamente de:
- Actualizar el sistema.
- Configurar la redirección de IP en el kernel (`sysctl net.ipv4.ip_forward=1`).
- Instalar **Docker** y **Docker Compose**.
- Detectar la IP pública de tu instancia de Lightsail.
- Iniciar el contenedor `wg-easy`.

---

## 🛠️ Instalación Manual (Paso a Paso)

Si prefieres hacerlo manualmente:

1. **Editar las variables de entorno:**
   Copia el archivo de plantilla `.env.example` a `.env`:
   ```bash
   cp .env.example .env
   nano .env
   ```
   Asegúrate de cambiar:
   - `WG_HOST`: Escribe tu IP pública estática de Lightsail.
   - `PASSWORD`: Escribe una contraseña segura para la Web UI.

2. **Habilitar IP Forwarding en la instancia:**
   ```bash
   sudo sysctl -w net.ipv4.ip_forward=1
   echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
   ```

3. **Iniciar el contenedor:**
   ```bash
   sudo docker compose up -d
   ```

---

## 📱 Uso del Panel Web y Conexión de Dispositivos

1. Abre tu navegador e ingresa a:
   ```text
   http://<TU_IP_PUBLICA_LIGHTSAIL>:51821
   ```
2. Ingresa la contraseña configurada en el archivo `.env`.
3. Haz clic en **"New Client"** (Nuevo Cliente) y asigna un nombre (ej. *MiCelular*, *LaptopTrabajo*).
4. **Conectar desde Celulares (Android / iOS):**
   - Abre la app oficial de WireGuard.
   - Presiona el botón `+` y selecciona **Escanear código QR**.
   - Escanea el código QR que se muestra en el panel Web. ¡Y listo!
5. **Conectar desde Computadoras (Windows / macOS / Linux):**
   - Descarga el archivo de configuración `.conf` desde el panel web.
   - Abre la aplicación de WireGuard en la computadora.
   - Haz clic en **Añadir túnel (Import tunnel)** y selecciona el archivo `.conf`.
   - Haz clic en **Activar**.

---

## 🔍 Comandos de Mantenimiento

- **Ver el estado del contenedor:**
  ```bash
  sudo docker compose ps
  ```

- **Ver logs en tiempo real:**
  ```bash
  sudo docker compose logs -f
  ```

- **Reiniciar el servidor VPN:**
  ```bash
  sudo docker compose restart
  ```

- **Detener el servicio:**
  ```bash
  sudo docker compose down
  ```

---

## 🔐 Seguridad Recomendada (Opcional)

Una vez que hayas creado tus clientes y perfiles VPN, puedes cerrar el puerto `51821/TCP` en el Firewall de Lightsail para prevenir accesos no autorizados al panel web. Solo vuelve a abrirlo cuando necesites agregar un nuevo dispositivo.
