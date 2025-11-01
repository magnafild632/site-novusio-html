#!/bin/bash

# =============================================================================
# Script de Verificação do Sistema - Site Novusio
# Diagnóstico completo do ambiente de produção
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
PROJECT_PATH="/home/$(whoami)/site-novusio"
SERVICE_NAME="novusio"
DOMAIN=""

# Função para log
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Função para erro
error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
}

# Função para aviso
warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Função para info
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Função para sucesso
success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              🔍 VERIFICAÇÃO DO SISTEMA 🔍                   ║"
    echo "║                                                              ║"
    echo "║              Diagnóstico Completo do Ambiente               ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Verificar informações do sistema
check_system_info() {
    echo -e "${CYAN}🖥️  Informações do Sistema${NC}"
    echo -e "${YELLOW}==========================${NC}"
    
    # Sistema operacional
    if [[ -f /etc/os-release ]]; then
        OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
        success "Sistema: $OS_NAME"
    else
        warning "Não foi possível determinar o sistema operacional"
    fi
    
    # Kernel
    KERNEL=$(uname -r)
    success "Kernel: $KERNEL"
    
    # Arquitetura
    ARCH=$(uname -m)
    success "Arquitetura: $ARCH"
    
    # Uptime
    UPTIME=$(uptime -p)
    success "Uptime: $UPTIME"
    
    # Load average
    LOAD=$(uptime | awk -F'load average:' '{print $2}')
    success "Load Average:$LOAD"
    
    echo ""
}

# Verificar uso de recursos
check_resources() {
    echo -e "${CYAN}💾 Recursos do Sistema${NC}"
    echo -e "${YELLOW}======================${NC}"
    
    # Memória
    MEMORY_INFO=$(free -h)
    echo "Memória:"
    echo "$MEMORY_INFO" | grep -E "(Mem|Swap)" | sed 's/^/  /'
    
    # Disco
    DISK_INFO=$(df -h / | tail -1)
    DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
    DISK_AVAIL=$(echo "$DISK_INFO" | awk '{print $4}')
    DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')
    
    if [[ ${DISK_PERCENT%?} -lt 80 ]]; then
        success "Disco: $DISK_USED usado, $DISK_AVAIL disponível ($DISK_PERCENT)"
    else
        warning "Disco: $DISK_USED usado, $DISK_AVAIL disponível ($DISK_PERCENT) - ATENÇÃO!"
    fi
    
    # CPU
    CPU_CORES=$(nproc)
    success "CPUs: $CPU_CORES cores"
    
    echo ""
}

# Verificar conectividade de rede
check_network() {
    echo -e "${CYAN}🌐 Conectividade de Rede${NC}"
    echo -e "${YELLOW}=========================${NC}"
    
    # IP público
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Não disponível")
    success "IP Público: $PUBLIC_IP"
    
    # IP local
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    success "IP Local: $LOCAL_IP"
    
    # Conectividade com internet
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        success "Conectividade: OK"
    else
        error "Conectividade: FALHA"
    fi
    
    # DNS
    if nslookup google.com > /dev/null 2>&1; then
        success "DNS: OK"
    else
        error "DNS: FALHA"
    fi
    
    echo ""
}

# Verificar serviços instalados
check_installed_services() {
    echo -e "${CYAN}🔧 Serviços Instalados${NC}"
    echo -e "${YELLOW}=======================${NC}"
    
    # Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        success "Node.js: $NODE_VERSION"
    else
        error "Node.js: NÃO INSTALADO"
    fi
    
    # npm
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        success "npm: $NPM_VERSION"
    else
        error "npm: NÃO INSTALADO"
    fi
    
    # Nginx
    if command -v nginx &> /dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2)
        success "Nginx: $NGINX_VERSION"
    else
        error "Nginx: NÃO INSTALADO"
    fi
    
    # Certbot
    if command -v certbot &> /dev/null; then
        CERTBOT_VERSION=$(certbot --version | cut -d' ' -f2)
        success "Certbot: $CERTBOT_VERSION"
    else
        warning "Certbot: NÃO INSTALADO"
    fi
    
    # SQLite
    if command -v sqlite3 &> /dev/null; then
        SQLITE_VERSION=$(sqlite3 --version | cut -d' ' -f1)
        success "SQLite: $SQLITE_VERSION"
    else
        error "SQLite: NÃO INSTALADO"
    fi
    
    echo ""
}

# Verificar status dos serviços
check_service_status() {
    echo -e "${CYAN}⚡ Status dos Serviços${NC}"
    echo -e "${YELLOW}=======================${NC}"
    
    # Serviço Novusio
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        success "Serviço Novusio: RODANDO"
        UPTIME=$(systemctl show "$SERVICE_NAME" --property=ActiveEnterTimestamp --value | cut -d' ' -f2-)
        success "Iniciado em: $UPTIME"
    else
        error "Serviço Novusio: PARADO"
    fi
    
    # Nginx
    if systemctl is-active --quiet nginx; then
        success "Nginx: RODANDO"
    else
        error "Nginx: PARADO"
    fi
    
    # Fail2ban
    if systemctl is-active --quiet fail2ban; then
        success "Fail2ban: RODANDO"
    else
        warning "Fail2ban: PARADO"
    fi
    
    echo ""
}

# Verificar projeto
check_project() {
    echo -e "${CYAN}📁 Projeto Novusio${NC}"
    echo -e "${YELLOW}===================${NC}"
    
    # Diretório do projeto
    if [[ -d "$PROJECT_PATH" ]]; then
        success "Diretório do projeto: OK"
        
        # Tamanho do projeto
        PROJECT_SIZE=$(du -sh "$PROJECT_PATH" | cut -f1)
        success "Tamanho: $PROJECT_SIZE"
        
        # Arquivo .env
        if [[ -f "$PROJECT_PATH/.env" ]]; then
            success "Arquivo .env: OK"
        else
            error "Arquivo .env: NÃO ENCONTRADO"
        fi
        
        # Banco de dados
        if [[ -f "$PROJECT_PATH/database.sqlite" ]]; then
            DB_SIZE=$(du -sh "$PROJECT_PATH/database.sqlite" | cut -f1)
            success "Banco de dados: OK ($DB_SIZE)"
        else
            error "Banco de dados: NÃO ENCONTRADO"
        fi
        
        # Build do cliente
        if [[ -d "$PROJECT_PATH/client/dist" ]]; then
            success "Build do cliente: OK"
        else
            warning "Build do cliente: NÃO ENCONTRADO"
        fi
        
    else
        error "Diretório do projeto: NÃO ENCONTRADO ($PROJECT_PATH)"
    fi
    
    echo ""
}

# Verificar configuração do Nginx
check_nginx_config() {
    echo -e "${CYAN}🌐 Configuração do Nginx${NC}"
    echo -e "${YELLOW}========================${NC}"
    
    # Arquivo de configuração
    if [[ -f "/etc/nginx/sites-available/novusio" ]]; then
        success "Configuração Nginx: OK"
    else
        error "Configuração Nginx: NÃO ENCONTRADA"
    fi
    
    # Site habilitado
    if [[ -L "/etc/nginx/sites-enabled/novusio" ]]; then
        success "Site habilitado: OK"
    else
        error "Site habilitado: NÃO"
    fi
    
    # Teste de configuração
    if nginx -t > /dev/null 2>&1; then
        success "Sintaxe Nginx: OK"
    else
        error "Sintaxe Nginx: ERRO"
    fi
    
    echo ""
}

# Verificar SSL
check_ssl() {
    echo -e "${CYAN}🔒 Certificados SSL${NC}"
    echo -e "${YELLOW}===================${NC}"
    
    # Verificar certificados
    if certbot certificates > /dev/null 2>&1; then
        CERT_INFO=$(certbot certificates 2>/dev/null | grep -A 5 "Certificate Name")
        if [[ -n "$CERT_INFO" ]]; then
            success "Certificados SSL: CONFIGURADOS"
            echo "$CERT_INFO" | sed 's/^/  /'
            
            # Verificar expiração
            EXPIRY=$(certbot certificates 2>/dev/null | grep "Expiry Date" | head -1 | cut -d: -f2-)
            success "Expiração: $EXPIRY"
        else
            warning "Certificados SSL: NÃO CONFIGURADOS"
        fi
    else
        warning "Certificados SSL: NÃO VERIFICÁVEIS"
    fi
    
    echo ""
}

# Verificar conectividade da aplicação
check_application() {
    echo -e "${CYAN}🚀 Aplicação${NC}"
    echo -e "${YELLOW}============${NC}"
    
    # Porta local
    if netstat -tlnp | grep -q ":3000 "; then
        success "Porta 3000: ABERTA"
    else
        error "Porta 3000: FECHADA"
    fi
    
    # Health check local
    if curl -f -s "http://localhost:3000/api/health" > /dev/null 2>&1; then
        success "API Local: RESPONDENDO"
    else
        error "API Local: NÃO RESPONDE"
    fi
    
    # Se houver domínio configurado
    if [[ -f "$PROJECT_PATH/.env" ]]; then
        DOMAIN=$(grep "^DOMAIN=" "$PROJECT_PATH/.env" | cut -d'=' -f2)
        if [[ -n "$DOMAIN" ]]; then
            # Health check externo
            if curl -f -s "https://$DOMAIN/api/health" > /dev/null 2>&1; then
                success "API Externa (HTTPS): RESPONDENDO"
            elif curl -f -s "http://$DOMAIN/api/health" > /dev/null 2>&1; then
                success "API Externa (HTTP): RESPONDENDO"
            else
                warning "API Externa: NÃO RESPONDE"
            fi
        fi
    fi
    
    echo ""
}

# Verificar logs
check_logs() {
    echo -e "${CYAN}📝 Logs${NC}"
    echo -e "${YELLOW}=======${NC}"
    
    # Logs do serviço
    if sudo journalctl -u "$SERVICE_NAME" --since "1 hour ago" --no-pager | grep -q .; then
        success "Logs do serviço: DISPONÍVEIS"
        
        # Últimos erros
        ERRORS=$(sudo journalctl -u "$SERVICE_NAME" --since "1 hour ago" --no-pager | grep -i error | wc -l)
        if [[ $ERRORS -gt 0 ]]; then
            warning "Erros na última hora: $ERRORS"
        else
            success "Erros na última hora: 0"
        fi
    else
        warning "Logs do serviço: NÃO DISPONÍVEIS"
    fi
    
    # Logs do Nginx
    if [[ -f "/var/log/nginx/novusio_error.log" ]]; then
        ERROR_SIZE=$(du -sh "/var/log/nginx/novusio_error.log" | cut -f1)
        success "Logs Nginx: OK ($ERROR_SIZE)"
    else
        warning "Logs Nginx: NÃO ENCONTRADOS"
    fi
    
    echo ""
}

# Verificar segurança
check_security() {
    echo -e "${CYAN}🔐 Segurança${NC}"
    echo -e "${YELLOW}============${NC}"
    
    # Firewall
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            success "Firewall UFW: ATIVO"
        else
            warning "Firewall UFW: INATIVO"
        fi
    else
        warning "Firewall UFW: NÃO INSTALADO"
    fi
    
    # Fail2ban
    if systemctl is-active --quiet fail2ban; then
        success "Fail2ban: ATIVO"
        
        # Verificar bans
        BANS=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}' || echo "0")
        if [[ "$BANS" -gt 0 ]]; then
            info "IPs banidos: $BANS"
        fi
    else
        warning "Fail2ban: INATIVO"
    fi
    
    # Permissões do projeto
    if [[ -d "$PROJECT_PATH" ]]; then
        PERMS=$(ls -ld "$PROJECT_PATH" | awk '{print $1}')
        if [[ "$PERMS" == "drwxr-xr-x" ]]; then
            success "Permissões do projeto: OK"
        else
            warning "Permissões do projeto: $PERMS"
        fi
    fi
    
    echo ""
}

# Verificar backups
check_backups() {
    echo -e "${CYAN}💾 Backups${NC}"
    echo -e "${YELLOW}==========${NC}"
    
    BACKUP_DIR="/home/$(whoami)/backups"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        BACKUP_COUNT=$(find "$BACKUP_DIR" -name "novusio_backup_*.tar.gz" | wc -l)
        if [[ $BACKUP_COUNT -gt 0 ]]; then
            success "Backups encontrados: $BACKUP_COUNT"
            
            # Último backup
            LAST_BACKUP=$(find "$BACKUP_DIR" -name "novusio_backup_*.tar.gz" -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
            if [[ -n "$LAST_BACKUP" ]]; then
                BACKUP_DATE=$(stat -c %y "$LAST_BACKUP" | cut -d' ' -f1)
                success "Último backup: $BACKUP_DATE"
            fi
            
            # Tamanho total dos backups
            BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
            success "Tamanho total: $BACKUP_SIZE"
        else
            warning "Nenhum backup encontrado"
        fi
    else
        warning "Diretório de backups não existe"
    fi
    
    echo ""
}

# Resumo e recomendações
show_summary() {
    echo -e "${CYAN}📊 Resumo e Recomendações${NC}"
    echo -e "${YELLOW}===========================${NC}"
    
    # Contar problemas
    ERRORS=$(grep -c "\[ERRO\]" <<< "$OUTPUT" || echo "0")
    WARNINGS=$(grep -c "\[AVISO\]" <<< "$OUTPUT" || echo "0")
    
    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        success "✅ Sistema funcionando perfeitamente!"
    elif [[ $ERRORS -eq 0 ]]; then
        info "⚠️  Sistema funcionando com $WARNINGS aviso(s)"
    else
        error "❌ Sistema com $ERRORS erro(s) e $WARNINGS aviso(s)"
    fi
    
    echo ""
    echo -e "${BLUE}Recomendações:${NC}"
    
    # Verificar se há atualizações disponíveis
    if command -v apt &> /dev/null; then
        UPDATES=$(apt list --upgradable 2>/dev/null | wc -l)
        if [[ $UPDATES -gt 1 ]]; then
            echo "- Execute 'sudo apt update && sudo apt upgrade' para atualizar o sistema"
        fi
    fi
    
    # Verificar espaço em disco
    DISK_PERCENT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $DISK_PERCENT -gt 80 ]]; then
        echo "- Limpe espaço em disco (atualmente ${DISK_PERCENT}% usado)"
    fi
    
    # Verificar logs de erro
    if sudo journalctl -u "$SERVICE_NAME" --since "1 day ago" --no-pager | grep -qi error; then
        echo "- Verifique os logs do serviço para erros recentes"
    fi
    
    echo ""
}

# Função principal
main() {
    show_banner
    
    OUTPUT=""
    
    check_system_info
    check_resources
    check_network
    check_installed_services
    check_service_status
    check_project
    check_nginx_config
    check_ssl
    check_application
    check_logs
    check_security
    check_backups
    show_summary
    
    echo -e "${GREEN}🎉 Verificação do sistema concluída!${NC}"
    echo ""
    echo "Para mais detalhes, execute:"
    echo "  sudo journalctl -u novusio -f    # Logs do serviço"
    echo "  sudo systemctl status novusio    # Status do serviço"
    echo "  tail -f /var/log/nginx/novusio_error.log  # Logs do Nginx"
}

# Executar função principal
main "$@"
