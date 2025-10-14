#!/bin/bash

# 🔧 Script de Correção - Problemas com APT Lock e NPM
# Script para resolver problemas comuns durante a instalação

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script deve ser executado como root."
    exit 1
fi

print_status "🔧 Iniciando correção de problemas..."

# 1. Resolver problemas de lock do APT
print_status "🔒 Resolvendo problemas de lock do APT..."

# Matar processos apt que podem estar travados
pkill -f apt-get || true
pkill -f apt || true
pkill -f dpkg || true

# Aguardar um pouco
sleep 3

# Remover locks se necessário
if [[ -f "/var/lib/apt/lists/lock" ]]; then
    print_warning "Removendo lock do APT..."
    rm -f /var/lib/apt/lists/lock
fi

if [[ -f "/var/lib/dpkg/lock-frontend" ]]; then
    print_warning "Removendo lock do DPKG frontend..."
    rm -f /var/lib/dpkg/lock-frontend
fi

if [[ -f "/var/lib/dpkg/lock" ]]; then
    print_warning "Removendo lock do DPKG..."
    rm -f /var/lib/dpkg/lock
fi

# Reconfigurar DPKG se necessário
print_status "Reconfigurando DPKG..."
dpkg --configure -a || true

# Limpar cache do APT
print_status "Limpando cache do APT..."
apt clean
apt autoclean

# Atualizar lista de pacotes
print_status "Atualizando lista de pacotes..."
apt update

print_success "Problemas de lock do APT resolvidos"

# 2. Verificar e corrigir Node.js/npm
print_status "📦 Verificando Node.js e NPM..."

# Verificar se Node.js está instalado
if ! command -v node &> /dev/null; then
    print_warning "Node.js não encontrado. Instalando..."
    apt install -y nodejs
else
    NODE_VERSION=$(node --version)
    print_success "Node.js encontrado: $NODE_VERSION"
fi

# Verificar se npm está instalado
if ! command -v npm &> /dev/null; then
    print_warning "NPM não encontrado. Instalando..."
    apt install -y npm
else
    NPM_VERSION=$(npm --version)
    print_success "NPM encontrado: v$NPM_VERSION"
fi

# 3. Instalar PM2 se necessário
print_status "⚡ Verificando PM2..."
if ! command -v pm2 &> /dev/null; then
    print_warning "PM2 não encontrado. Instalando..."
    npm install -g pm2
else
    print_success "PM2 já está instalado"
fi

# 4. Verificar outros pacotes essenciais
print_status "🔍 Verificando pacotes essenciais..."

ESSENTIAL_PACKAGES=(
    "curl"
    "wget"
    "git"
    "unzip"
    "software-properties-common"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "lsb-release"
    "nginx"
    "certbot"
    "python3-certbot-nginx"
    "fail2ban"
)

for package in "${ESSENTIAL_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        print_warning "Pacote $package não encontrado. Instalando..."
        apt install -y "$package"
    else
        print_success "Pacote $package já está instalado"
    fi
done

# 5. Verificar serviços
print_status "🔄 Verificando serviços..."

# Verificar se nginx está rodando
if systemctl is-active --quiet nginx; then
    print_success "Nginx está rodando"
else
    print_warning "Nginx não está rodando. Iniciando..."
    systemctl start nginx
    systemctl enable nginx
fi

# Verificar se fail2ban está rodando
if systemctl is-active --quiet fail2ban; then
    print_success "Fail2ban está rodando"
else
    print_warning "Fail2ban não está rodando. Iniciando..."
    systemctl start fail2ban
    systemctl enable fail2ban
fi

print_success "🎉 Correção concluída com sucesso!"
echo ""
print_status "📋 Resumo:"
echo "• Problemas de lock do APT resolvidos"
echo "• Node.js e NPM verificados/instalados"
echo "• PM2 verificado/instalado"
echo "• Pacotes essenciais verificados"
echo "• Serviços verificados/iniciados"
echo ""
print_status "🚀 Agora você pode executar novamente:"
echo "   ./install.sh"
echo ""
