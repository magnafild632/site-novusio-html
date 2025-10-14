#!/bin/bash

# 🎛️ Gerenciador Site Novusio
# Script para gerenciar a aplicação de forma fácil

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

# Configurações
SERVICE_NAME="novusio"
APP_DIR="/opt/novusio"
LOG_DIR="/var/log/novusio"

# Função para mostrar ajuda
show_help() {
    echo ""
    echo "🎛️ Gerenciador Site Novusio"
    echo ""
    echo "Uso: novusio-manager [comando]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  start       Iniciar aplicação"
    echo "  stop        Parar aplicação"
    echo "  restart     Reiniciar aplicação"
    echo "  status      Mostrar status da aplicação"
    echo "  logs        Mostrar logs em tempo real"
    echo "  deploy      Fazer deploy da aplicação"
    echo "  backup      Criar backup"
    echo "  restore     Restaurar backup"
    echo "  ssl         Configurar/renovar SSL"
    echo "  update      Atualizar sistema"
    echo "  info        Informações do sistema"
    echo "  help        Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  novusio-manager status"
    echo "  novusio-manager logs"
    echo "  novusio-manager deploy"
    echo ""
}

# Função para mostrar status
show_status() {
    echo ""
    echo "📊 Status do Site Novusio"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Status da aplicação
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_success "✅ Aplicação: RODANDO"
    else
        print_error "❌ Aplicação: PARADA"
    fi
    
    # Status do Nginx
    if systemctl is-active --quiet nginx; then
        print_success "✅ Nginx: RODANDO"
    else
        print_error "❌ Nginx: PARADO"
    fi
    
    # Status do Fail2ban
    if systemctl is-active --quiet fail2ban; then
        print_success "✅ Fail2ban: ATIVO"
    else
        print_warning "⚠️ Fail2ban: INATIVO"
    fi
    
    # Status do SSL
    if [[ -d "/etc/letsencrypt/live" ]]; then
        print_success "✅ SSL: CONFIGURADO"
    else
        print_warning "⚠️ SSL: NÃO CONFIGURADO"
    fi
    
    # Uso de memória
    MEMORY_USAGE=$(ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -2 | tail -1 | awk '{print $4}')
    CPU_USAGE=$(ps -o pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -2 | tail -1 | awk '{print $5}')
    
    echo ""
    echo "📈 Recursos:"
    echo "• Uso de memória: ${MEMORY_USAGE}%"
    echo "• Uso de CPU: ${CPU_USAGE}%"
    
    # Portas em uso
    echo ""
    echo "🌐 Portas:"
    if netstat -tlnp 2>/dev/null | grep -q ":3000"; then
        echo "• Porta 3000: ✅ (Aplicação)"
    else
        echo "• Porta 3000: ❌ (Aplicação)"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":80"; then
        echo "• Porta 80: ✅ (HTTP)"
    else
        echo "• Porta 80: ❌ (HTTP)"
    fi
    
    if netstat -tlnp 2>/dev/null | grep -q ":443"; then
        echo "• Porta 443: ✅ (HTTPS)"
    else
        echo "• Porta 443: ❌ (HTTPS)"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Função para mostrar logs
show_logs() {
    echo ""
    echo "📋 Logs do Site Novusio (Ctrl+C para sair)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        journalctl -u $SERVICE_NAME -f --no-pager
    else
        print_error "Aplicação não está rodando"
        exit 1
    fi
}

# Função para fazer deploy
do_deploy() {
    echo ""
    print_status "🚀 Iniciando deploy..."
    
    if [[ -f "$APP_DIR/app/instalador/deploy.sh" ]]; then
        cd "$APP_DIR/app"
        sudo -u novusio ./instalador/deploy.sh
    else
        print_error "Script de deploy não encontrado"
        exit 1
    fi
}

# Função para fazer backup
do_backup() {
    echo ""
    print_status "💾 Criando backup..."
    
    if [[ -f "$APP_DIR/app/instalador/backup.sh" ]]; then
        sudo -u novusio "$APP_DIR/app/instalador/backup.sh"
    else
        print_error "Script de backup não encontrado"
        exit 1
    fi
}

# Função para configurar SSL
do_ssl() {
    echo ""
    print_status "🔒 Configurando SSL..."
    
    if [[ -f "$APP_DIR/app/instalador/setup-ssl.sh" ]]; then
        sudo "$APP_DIR/app/instalador/setup-ssl.sh"
    else
        print_error "Script de SSL não encontrado"
        exit 1
    fi
}

# Função para mostrar informações do sistema
show_info() {
    echo ""
    echo "ℹ️ Informações do Sistema"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "🖥️ Sistema:"
    echo "• OS: $(lsb_release -d | cut -f2)"
    echo "• Kernel: $(uname -r)"
    echo "• Arquitetura: $(uname -m)"
    echo "• Uptime: $(uptime -p)"
    
    echo ""
    echo "📦 Aplicação:"
    echo "• Diretório: $APP_DIR"
    echo "• Usuário: $(stat -c %U $APP_DIR)"
    echo "• Versão Node.js: $(node --version)"
    echo "• Versão NPM: $(npm --version)"
    
    echo ""
    echo "🌐 Serviços:"
    echo "• Nginx: $(nginx -v 2>&1 | cut -d' ' -f3)"
    echo "• PM2: $(pm2 --version 2>/dev/null || echo 'Não instalado')"
    echo "• Certbot: $(certbot --version 2>/dev/null || echo 'Não instalado')"
    
    echo ""
    echo "💾 Espaço em disco:"
    df -h | grep -E "(Filesystem|/dev/)" | head -5
    
    echo ""
    echo "🧠 Memória:"
    free -h
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Função para atualizar sistema
do_update() {
    echo ""
    print_status "🔄 Atualizando sistema..."
    
    sudo apt update
    sudo apt upgrade -y
    
    print_success "Sistema atualizado"
}

# Processar comando
case "${1:-help}" in
    start)
        print_status "🚀 Iniciando aplicação..."
        sudo systemctl start $SERVICE_NAME
        print_success "Aplicação iniciada"
        ;;
    
    stop)
        print_status "⏹️ Parando aplicação..."
        sudo systemctl stop $SERVICE_NAME
        print_success "Aplicação parada"
        ;;
    
    restart)
        print_status "🔄 Reiniciando aplicação..."
        sudo systemctl restart $SERVICE_NAME
        print_success "Aplicação reiniciada"
        ;;
    
    status)
        show_status
        ;;
    
    logs)
        show_logs
        ;;
    
    deploy)
        do_deploy
        ;;
    
    backup)
        do_backup
        ;;
    
    ssl)
        do_ssl
        ;;
    
    update)
        do_update
        ;;
    
    info)
        show_info
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        print_error "Comando inválido: $1"
        show_help
        exit 1
        ;;
esac
