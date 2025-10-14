#!/bin/bash

# 🔍 Script de Diagnóstico - Site Novusio
# Script para diagnosticar problemas comuns

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

print_title() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script deve ser executado como root."
    exit 1
fi

print_title "🔍 DIAGNÓSTICO DO SISTEMA - SITE NOVUSIO"

# 1. Informações do Sistema
print_status "🖥️ Informações do Sistema:"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Arquitetura: $(uname -m)"
echo "Uptime: $(uptime -p)"
echo ""

# 2. Verificar processos apt
print_status "🔒 Verificando processos APT:"
if pgrep apt > /dev/null; then
    print_warning "Processos APT em execução:"
    ps aux | grep apt | grep -v grep
    echo ""
    print_warning "Solução: Execute ./fix-apt-lock.sh"
else
    print_success "Nenhum processo APT em execução"
fi

# 3. Verificar locks do APT
print_status "🔐 Verificando locks do APT:"
if [[ -f "/var/lib/apt/lists/lock" ]]; then
    print_error "Lock do APT encontrado: /var/lib/apt/lists/lock"
    echo "Processo: $(lsof /var/lib/apt/lists/lock 2>/dev/null || echo 'N/A')"
else
    print_success "Lock do APT não encontrado"
fi

if [[ -f "/var/lib/dpkg/lock" ]]; then
    print_error "Lock do DPKG encontrado: /var/lib/dpkg/lock"
    echo "Processo: $(lsof /var/lib/dpkg/lock 2>/dev/null || echo 'N/A')"
else
    print_success "Lock do DPKG não encontrado"
fi
echo ""

# 4. Verificar Node.js e NPM
print_status "📦 Verificando Node.js e NPM:"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js: $NODE_VERSION"
else
    print_error "Node.js não encontrado"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "NPM: v$NPM_VERSION"
else
    print_error "NPM não encontrado"
fi

if command -v pm2 &> /dev/null; then
    PM2_VERSION=$(pm2 --version)
    print_success "PM2: v$PM2_VERSION"
else
    print_error "PM2 não encontrado"
fi
echo ""

# 5. Verificar pacotes essenciais
print_status "📋 Verificando pacotes essenciais:"
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
    if dpkg -l | grep -q "^ii  $package "; then
        VERSION=$(dpkg -l | grep "^ii  $package " | awk '{print $3}')
        print_success "$package: $VERSION"
    else
        print_error "$package: NÃO INSTALADO"
    fi
done
echo ""

# 6. Verificar serviços
print_status "🔄 Verificando serviços:"
SERVICES=("nginx" "fail2ban" "novusio")

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "^$service.service"; then
        if systemctl is-active --quiet "$service"; then
            print_success "$service: ATIVO"
        else
            print_warning "$service: INATIVO"
        fi
        
        if systemctl is-enabled --quiet "$service"; then
            print_success "$service: HABILITADO"
        else
            print_warning "$service: DESABILITADO"
        fi
    else
        print_error "$service: NÃO ENCONTRADO"
    fi
done
echo ""

# 7. Verificar portas
print_status "🌐 Verificando portas:"
if command -v netstat &> /dev/null; then
    print_status "Portas em uso:"
    netstat -tlnp | grep -E ":(22|80|443|3000)" || print_warning "Nenhuma porta relevante em uso"
else
    print_warning "netstat não encontrado"
fi
echo ""

# 8. Verificar espaço em disco
print_status "💾 Verificando espaço em disco:"
df -h | grep -E "(Filesystem|/dev/)" | head -5
echo ""

# 9. Verificar memória
print_status "🧠 Verificando memória:"
free -h
echo ""

# 10. Verificar logs de erro
print_status "📋 Verificando logs de erro recentes:"
if [[ -f "/var/log/syslog" ]]; then
    print_status "Últimos erros no syslog:"
    tail -20 /var/log/syslog | grep -i error | tail -5 || print_success "Nenhum erro recente encontrado"
fi
echo ""

# 11. Verificar configuração da aplicação
print_status "⚙️ Verificando configuração da aplicação:"
if [[ -f "/opt/novusio/.env" ]]; then
    print_success "Arquivo .env encontrado"
    if [[ -f "/opt/novusio/config.conf" ]]; then
        print_success "Arquivo config.conf encontrado"
    else
        print_warning "Arquivo config.conf não encontrado"
    fi
else
    print_warning "Arquivo .env não encontrado"
fi

if [[ -d "/opt/novusio/app" ]]; then
    print_success "Diretório da aplicação encontrado"
else
    print_warning "Diretório da aplicação não encontrado"
fi
echo ""

# 12. Verificar usuário novusio
print_status "👤 Verificando usuário novusio:"
if id "novusio" &>/dev/null; then
    print_success "Usuário novusio encontrado"
    echo "UID: $(id -u novusio)"
    echo "GID: $(id -g novusio)"
    echo "Home: $(getent passwd novusio | cut -d: -f6)"
else
    print_error "Usuário novusio não encontrado"
fi
echo ""

# Resumo
print_title "📊 RESUMO DO DIAGNÓSTICO"

# Contar problemas
ERRORS=0
WARNINGS=0

# Verificar problemas críticos
if ! command -v node &> /dev/null; then ((ERRORS++)); fi
if ! command -v npm &> /dev/null; then ((ERRORS++)); fi
if ! command -v pm2 &> /dev/null; then ((ERRORS++)); fi
if pgrep apt > /dev/null; then ((WARNINGS++)); fi
if [[ -f "/var/lib/apt/lists/lock" ]]; then ((WARNINGS++)); fi

echo "Problemas encontrados:"
echo "• Erros críticos: $ERRORS"
echo "• Avisos: $WARNINGS"
echo ""

if [[ $ERRORS -gt 0 ]]; then
    print_error "❌ Problemas críticos encontrados!"
    print_status "Execute ./fix-apt-lock.sh para corrigir"
elif [[ $WARNINGS -gt 0 ]]; then
    print_warning "⚠️ Avisos encontrados"
    print_status "Execute ./fix-apt-lock.sh para corrigir"
else
    print_success "✅ Sistema funcionando corretamente!"
fi

echo ""
print_status "🔧 Comandos úteis:"
echo "• Corrigir problemas: ./fix-apt-lock.sh"
echo "• Instalar sistema: ./install.sh"
echo "• Verificar sistema: ./verificar-sistema.sh"
echo "• Menu principal: ./menu-principal.sh"
echo ""
