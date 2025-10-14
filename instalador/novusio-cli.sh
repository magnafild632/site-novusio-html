#!/bin/bash

# =============================================================================
# NOVUSIO CLI - COMANDOS RÁPIDOS
# =============================================================================
# Script para comandos rápidos de gerenciamento do Novusio
# Uso: ./novusio-cli.sh [comando]
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função de ajuda
show_help() {
    echo -e "${BLUE}🚀 NOVUSIO CLI - Comandos Rápidos${NC}"
    echo "=================================="
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  start       - Iniciar aplicação"
    echo "  stop        - Parar aplicação"
    echo "  restart     - Reiniciar aplicação"
    echo "  status      - Status da aplicação"
    echo "  logs        - Ver logs da aplicação"
    echo "  update      - Atualizar aplicação"
    echo "  backup      - Fazer backup manual"
    echo "  monitor     - Executar monitoramento"
    echo "  ssl         - Renovar certificado SSL"
    echo "  nginx       - Recarregar Nginx"
    echo "  maintenance - Manutenção rápida"
    echo "  info        - Informações do sistema"
    echo "  menu        - Abrir menu interativo"
    echo "  help        - Mostrar esta ajuda"
    echo ""
}

# Verificar se está como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ Execute como root: sudo $0 [comando]${NC}"
        exit 1
    fi
}

# Iniciar aplicação
start_app() {
    echo -e "${GREEN}🚀 Iniciando aplicação...${NC}"
    cd /home/novusio
    sudo -u novusio pm2 start ecosystem.config.js --env production
    echo -e "${GREEN}✅ Aplicação iniciada!${NC}"
}

# Parar aplicação
stop_app() {
    echo -e "${YELLOW}⏹️ Parando aplicação...${NC}"
    sudo -u novusio pm2 stop novusio-server
    echo -e "${GREEN}✅ Aplicação parada!${NC}"
}

# Reiniciar aplicação
restart_app() {
    echo -e "${BLUE}🔄 Reiniciando aplicação...${NC}"
    sudo -u novusio pm2 restart novusio-server
    echo -e "${GREEN}✅ Aplicação reiniciada!${NC}"
}

# Status da aplicação
status_app() {
    echo -e "${BLUE}📊 Status da Aplicação:${NC}"
    sudo -u novusio pm2 status
    echo ""
    echo -e "${BLUE}💻 Recursos do Sistema:${NC}"
    echo "Memória: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "Disco: $(df -h / | awk 'NR==2{print $5}') usado"
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
}

# Ver logs
logs_app() {
    echo -e "${BLUE}📋 Logs da Aplicação:${NC}"
    sudo -u novusio pm2 logs --lines 50
}

# Atualizar aplicação
update_app() {
    echo -e "${BLUE}🔄 Atualizando aplicação...${NC}"
    cd /home/novusio
    
    # Backup antes da atualização
    echo -e "${YELLOW}💾 Criando backup...${NC}"
    /usr/local/bin/novusio-backup.sh 2>/dev/null || true
    
    # Parar aplicação
    sudo -u novusio pm2 stop novusio-server
    
    # Atualizar código
    echo -e "${BLUE}📥 Atualizando código...${NC}"
    git pull origin main
    
    # Instalar dependências
    echo -e "${BLUE}📦 Instalando dependências...${NC}"
    npm ci --production
    
    if [[ -d "client" ]]; then
        cd client
        npm ci
        npm run build
        cd ..
    fi
    
    # Reiniciar aplicação
    sudo -u novusio pm2 start ecosystem.config.js --env production
    sudo -u novusio pm2 save
    
    echo -e "${GREEN}✅ Aplicação atualizada!${NC}"
}

# Backup manual
backup_manual() {
    echo -e "${BLUE}💾 Executando backup manual...${NC}"
    /usr/local/bin/novusio-backup.sh
    echo -e "${GREEN}✅ Backup concluído!${NC}"
}

# Monitoramento
monitor_app() {
    echo -e "${BLUE}📊 Executando monitoramento...${NC}"
    /usr/local/bin/novusio-monitor.sh
}

# Renovar SSL
renew_ssl() {
    echo -e "${BLUE}🔒 Renovando certificado SSL...${NC}"
    certbot renew
    systemctl reload nginx
    echo -e "${GREEN}✅ SSL renovado!${NC}"
}

# Recarregar Nginx
reload_nginx() {
    echo -e "${BLUE}🌐 Recarregando Nginx...${NC}"
    nginx -t && systemctl reload nginx
    echo -e "${GREEN}✅ Nginx recarregado!${NC}"
}

# Manutenção rápida
quick_maintenance() {
    echo -e "${BLUE}🔧 Executando manutenção rápida...${NC}"
    
    # Reiniciar aplicação
    sudo -u novusio pm2 restart novusio-server
    
    # Recarregar Nginx
    systemctl reload nginx
    
    # Limpar logs antigos
    find /var/log/novusio -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    # Limpar cache
    apt-get autoremove -y 2>/dev/null || true
    apt-get autoclean 2>/dev/null || true
    
    echo -e "${GREEN}✅ Manutenção concluída!${NC}"
}

# Informações do sistema
system_info() {
    echo -e "${BLUE}💻 Informações do Sistema:${NC}"
    echo "=================================="
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime)"
    echo "Sistema: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo ""
    echo -e "${BLUE}💾 Recursos:${NC}"
    echo "Memória: $(free -h | awk 'NR==2{printf "%.1f%% (%s/%s)", $3*100/$2, $3, $2}')"
    echo "Disco: $(df -h / | awk 'NR==2{printf "%s (%s livres)", $5, $4}')"
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
    echo ""
    echo -e "${BLUE}🔄 Aplicação:${NC}"
    sudo -u novusio pm2 list | grep novusio-server || echo "Aplicação não encontrada"
    echo ""
    echo -e "${BLUE}🌐 Serviços:${NC}"
    services=("nginx" "fail2ban")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "  ✅ $service ativo"
        else
            echo "  ❌ $service inativo"
        fi
    done
}

# Abrir menu interativo
open_menu() {
    echo -e "${BLUE}🚀 Abrindo menu interativo...${NC}"
    ./deploy.sh
}

# Função principal
main() {
    case "${1:-help}" in
        start)
            check_root
            start_app
            ;;
        stop)
            check_root
            stop_app
            ;;
        restart)
            check_root
            restart_app
            ;;
        status)
            check_root
            status_app
            ;;
        logs)
            check_root
            logs_app
            ;;
        update)
            check_root
            update_app
            ;;
        backup)
            check_root
            backup_manual
            ;;
        monitor)
            check_root
            monitor_app
            ;;
        ssl)
            check_root
            renew_ssl
            ;;
        nginx)
            check_root
            reload_nginx
            ;;
        maintenance)
            check_root
            quick_maintenance
            ;;
        info)
            check_root
            system_info
            ;;
        menu)
            check_root
            open_menu
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Comando inválido: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
