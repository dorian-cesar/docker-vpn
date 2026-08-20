#!/bin/bash

# ==============================================================================
# Script de Instalación Automatizada de WireGuard VPN en AWS Lightsail
# OS Compatibles: Ubuntu 22.04 / 24.04 LTS, Debian 11/12
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Iniciando instalación de WireGuard VPN (wg-easy) en AWS Lightsail ===${NC}\n"

# 1. Comprobar permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Este script debe ejecutarse con permisos de superusuario (sudo).${NC}"
  echo "Uso: sudo bash install-lightsail.sh"
  exit 1
fi

# 2. Actualizar paquetes del sistema
echo -e "${GREEN}[1/5] Actualizando repositorio del sistema...${NC}"
apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release iptables wireguard wireguard-tools
modprobe wireguard 2>/dev/null || true

# 3. Habilitar Reenvío de IP (IPv4 Forwarding) en Sysctl
echo -e "${GREEN}[2/5] Configurando el Kernel de Linux (ip_forward=1)...${NC}"
sysctl -w net.ipv4.ip_forward=1
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -p /etc/sysctl.conf 2>/dev/null || true

# 4. Instalar Docker y Docker Compose si no están instalados
echo -e "${GREEN}[3/5] Verificando e instalando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker Engine..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo "Docker ya está instalado."
fi

if ! docker compose version &> /dev/null; then
    echo "Instalando el complemento Docker Compose..."
    apt-get install -y docker-compose-plugin
fi

# 5. Obtener la IP Pública de AWS Lightsail
PUBLIC_IP=$(curl -s -4 https://ifconfig.me || curl -s -4 https://api.ipify.org || echo "")

if [ -f ".env" ]; then
    # Si WG_HOST es el valor por defecto, actualizarlo con la IP detectada
    if grep -q "WG_HOST=TU_IP_PUBLICA_LIGHTSAIL" .env && [ -n "$PUBLIC_IP" ]; then
        echo -e "${YELLOW}Detectada IP Pública de Lightsail: ${PUBLIC_IP}${NC}"
        sed -i "s/WG_HOST=TU_IP_PUBLICA_LIGHTSAIL/WG_HOST=${PUBLIC_IP}/g" .env
    fi
fi

# 6. Levantar el servicio con Docker Compose
echo -e "${GREEN}[4/5] Desplegando el contenedor WireGuard (wg-easy)...${NC}"
docker compose down 2>/dev/null || true
docker compose up -d

echo -e "\n${GREEN}[5/5] ¡Despliegue completado con éxito!${NC}\n"

echo -e "${CYAN}========================================================================${NC}"
echo -e "${GREEN}  VPN WireGuard activa y funcionando:${NC}"
if [ -n "$PUBLIC_IP" ]; then
    echo -e "  - IP de la VPN: ${YELLOW}${PUBLIC_IP}${NC}"
    echo -e "  - Panel de Control (Web UI): ${YELLOW}http://${PUBLIC_IP}:51821${NC}"
else
    echo -e "  - Panel de Control (Web UI): ${YELLOW}http://<IP-DE-TU-LIGHTSAIL>:51821${NC}"
fi
echo -e "  - Contraseña por defecto: Definida en el archivo .env"
echo -e "${CYAN}========================================================================${NC}"
echo -e "${YELLOW}RECORDATORIO IMPORTANTE PARA AWS LIGHTSAIL:${NC}"
echo -e "Asegúrate de abrir los siguientes puertos en la consola de AWS Lightsail"
echo -e "(Sección: Instancia -> Redes / Networking -> Firewall):"
echo -e "  1. Regla UDP:  Puerto ${GREEN}51820${NC}"
echo -e "  2. Regla TCP:  Puerto ${GREEN}51821${NC}"
echo -e "${CYAN}========================================================================${NC}\n"
