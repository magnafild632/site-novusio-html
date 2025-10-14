#!/bin/bash

# =============================================================================
# NOVUSIO MANAGER - GERENCIADOR COMPLETO
# =============================================================================
# Script unificado para gerenciar, monitorar e manter o Novusio
# Uso: ./novusio-manager.sh [comando] [opções]
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
PROJECT_DIR="/home/novusio"
APP_NAME="novusio-server"
DOMAIN="novusiopy.com"
LOG_FILE="/var/log/novusio-manager.log"
ALERT_LOG="/var/log/novusio-alerts.log"

# Função de log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

alert() {
    echo -e "${RED}[ALERT]${NC} $1" | tee -a "$ALERT_LOG"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Função de ajuda
show_help() {
    echo -e "${BLUE}🚀 NOVUSIO MANAGER - Gerenciador Completo${NC}"
    echo "=============================================="
    echo ""
    echo "Uso: $0 [comando] [opções]"
    echo ""
    echo -e "${BLUE}📱 COMANDOS DE APLICAÇÃO:${NC}"
    echo "  start       - Iniciar aplicação"
    echo "  stop        - Parar aplicação"
    echo "  restart     - Reiniciar aplicação"
    echo "  status      - Status da aplicação"
    echo "  logs        - Ver logs da aplicação"
    echo "  update      - Atualizar aplicação"
    echo ""
    echo -e "${BLUE}🔧 COMANDOS DE MANUTENÇÃO:${NC}"
    echo "  backup      - Fazer backup manual"
    echo "  monitor     - Executar monitoramento completo"
    echo "  maintenance - Manutenção rápida do sistema"
    echo "  cleanup     - Limpeza do sistema"
    echo ""
    echo -e "${BLUE}🌐 COMANDOS DE SERVIÇOS:${NC}"
    echo "  ssl         - Renovar certificado SSL"
    echo "  nginx       - Recarregar Nginx"
    echo "  services    - Status dos serviços"
    echo ""
    echo -e "${BLUE}📊 COMANDOS DE MONITORAMENTO:${NC}"
    echo "  health      - Verificação rápida de saúde"
    echo "  resources   - Recursos do sistema"
    echo "  security    - Verificação de segurança"
    echo "  report      - Gerar relatório completo"
    echo ""
    echo -e "${BLUE}⚙️ COMANDOS DE CONFIGURAÇÃO:${NC}"
    echo "  deploy      - Deploy completo"
    echo "  config      - Ver configurações"
    echo "  info        - Informações do sistema"
    echo "  menu        - Menu interativo"
    echo ""
    echo "Exemplos:"
    echo "  $0 start                    # Iniciar aplicação"
    echo "  $0 monitor                  # Monitoramento completo"
    echo "  $0 backup                   # Backup manual"
    echo "  $0 maintenance              # Manutenção rápida"
    echo ""
}

# Verificar se está como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ Execute como root: sudo $0 [comando]${NC}"
        exit 1
    fi
}

# =============================================================================
# COMANDOS DE APLICAÇÃO
# =============================================================================

start_app() {
    log "🚀 Iniciando aplicação..."
    cd "$PROJECT_DIR"
    sudo -u novusio pm2 start ecosystem.config.js --env production
    sudo -u novusio pm2 save
    log "✅ Aplicação iniciada!"
}

stop_app() {
    log "⏹️ Parando aplicação..."
    sudo -u novusio pm2 stop "$APP_NAME"
    log "✅ Aplicação parada!"
}

restart_app() {
    log "🔄 Reiniciando aplicação..."
    sudo -u novusio pm2 restart "$APP_NAME"
    log "✅ Aplicação reiniciada!"
}

status_app() {
    log "📊 Status da Aplicação:"
    sudo -u novusio pm2 list
    echo ""
    log "💻 Recursos do Sistema:"
    echo "Memória: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "Disco: $(df -h / | awk 'NR==2{print $5}') usado"
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
}

logs_app() {
    log "📋 Logs da Aplicação:"
    sudo -u novusio pm2 logs --lines 50
}

update_app() {
    log "🔄 Atualizando aplicação..."
    cd "$PROJECT_DIR"
    
    # Backup antes da atualização
    log "💾 Criando backup..."
    backup_manual
    
    # Parar aplicação
    sudo -u novusio pm2 stop "$APP_NAME"
    
    # PRIMEIRO: Corrigir permissões do Git ANTES de qualquer operação Git
    log "🔧 Corrigindo permissões do Git..."
    if [[ -d ".git" ]]; then
        chown -R novusio:novusio .git
        chmod -R 755 .git
        
        # Corrigir arquivos específicos que podem causar problemas
        if [[ -f ".git/FETCH_HEAD" ]]; then
            chown novusio:novusio .git/FETCH_HEAD
            chmod 644 .git/FETCH_HEAD
            log "✅ FETCH_HEAD corrigido"
        fi
        
        if [[ -f ".git/index" ]]; then
            chown novusio:novusio .git/index
            chmod 644 .git/index
            log "✅ index corrigido"
        fi
        
        # Corrigir refs e objects também
        if [[ -d ".git/refs" ]]; then
            chown -R novusio:novusio .git/refs
            chmod -R 755 .git/refs
        fi
        
        if [[ -d ".git/objects" ]]; then
            chown -R novusio:novusio .git/objects
            chmod -R 755 .git/objects
        fi
        
        log "✅ Todas as permissões do Git corrigidas"
    fi
    
    # Configurar Git para evitar conflitos
    log "⚙️  Configurando Git..."
    sudo -u novusio git config --global pull.rebase false 2>/dev/null || true
    sudo -u novusio git config --global user.name "Novusio Server" 2>/dev/null || true
    sudo -u novusio git config --global user.email "admin@novusiopy.com" 2>/dev/null || true
    
    # SEGUNDO: Agora fazer o git pull
    log "📥 Atualizando código do repositório..."
    if ! sudo -u novusio git pull origin main; then
        warning "⚠️  Git pull falhou, tentando resetar..."
        sudo -u novusio git reset --hard HEAD 2>/dev/null || true
        sudo -u novusio git clean -fd 2>/dev/null || true
        sudo -u novusio git pull origin main
    fi
    
    # Instalar dependências
    log "📦 Instalando dependências..."
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
    
    log "✅ Aplicação atualizada!"
}

# =============================================================================
# COMANDOS DE MANUTENÇÃO
# =============================================================================

backup_manual() {
    log "💾 Executando backup manual..."
    if [[ -f "$PROJECT_DIR/instalador/backup.sh" ]]; then
        bash "$PROJECT_DIR/instalador/backup.sh"
    else
        alert "❌ Script de backup não encontrado"
    fi
    log "✅ Backup concluído!"
}

monitor_app() {
    log "📊 Executando monitoramento completo..."
    
    # Status da aplicação
    if pm2 list | grep -q "$APP_NAME.*online"; then
        log "✅ Aplicação $APP_NAME está online"
    else
        alert "❌ Aplicação $APP_NAME não está rodando!"
        restart_app
    fi
    
    # Recursos do sistema
    check_system_resources
    
    # Conectividade
    check_connectivity
    
    # Serviços essenciais
    check_services
    
    # SSL
    check_ssl
    
    log "✅ Monitoramento concluído!"
}

maintenance_app() {
    log "🔧 Executando manutenção rápida..."
    
    # Reiniciar aplicação
    restart_app
    
    # Recarregar Nginx
    systemctl reload nginx
    
    # Limpar logs antigos
    find /var/log/novusio -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    # Limpar cache
    apt-get autoremove -y 2>/dev/null || true
    apt-get autoclean 2>/dev/null || true
    
    log "✅ Manutenção concluída!"
}

cleanup_system() {
    log "🧹 Executando limpeza do sistema..."
    
    # Limpar logs antigos
    find /var/log -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    # Limpar cache do apt
    apt-get clean
    apt-get autoremove -y
    
    # Limpar cache do npm (se existir)
    if [[ -d "/home/novusio/.npm" ]]; then
        sudo -u novusio npm cache clean --force
    fi
    
    # Limpar arquivos temporários
    rm -rf /tmp/*
    
    log "✅ Limpeza concluída!"
}


# =============================================================================
# COMANDOS DE SERVIÇOS
# =============================================================================

renew_ssl() {
    log "🔒 Renovando certificado SSL..."
    certbot renew --quiet
    systemctl reload nginx
    log "✅ SSL renovado!"
}

reload_nginx() {
    log "🌐 Recarregando Nginx..."
    nginx -t && systemctl reload nginx
    log "✅ Nginx recarregado!"
}

check_services() {
    log "🔍 Verificando serviços essenciais..."
    
    services=("nginx" "fail2ban")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "✅ $service está ativo"
        else
            alert "❌ $service não está ativo"
            systemctl start "$service" 2>/dev/null || true
        fi
    done
}

# =============================================================================
# COMANDOS DE MONITORAMENTO
# =============================================================================

health_check() {
    log "🏥 Verificação rápida de saúde..."
    
    # Aplicação
    if curl -s -o /dev/null "http://localhost:3000/api/health"; then
        log "✅ API funcionando"
    else
        alert "❌ API não responde"
    fi
    
    # Recursos básicos
    MEMORY_USAGE=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
        alert "⚠️ Memória alta: ${MEMORY_USAGE}%"
    else
        log "✅ Memória OK: ${MEMORY_USAGE}%"
    fi
    
    # Disco
    DISK_USAGE=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    if [[ "$DISK_USAGE" -gt 85 ]]; then
        alert "⚠️ Disco alto: ${DISK_USAGE}%"
    else
        log "✅ Disco OK: ${DISK_USAGE}%"
    fi
}

check_system_resources() {
    log "💻 Recursos do Sistema:"
    
    # Memória
    MEMORY_INFO=$(free -h)
    MEMORY_USED=$(echo "$MEMORY_INFO" | awk 'NR==2{printf "%.1f", $3*100/$2}')
    info "  - Memória: ${MEMORY_USED}% usado"
    
    # CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    info "  - CPU: ${CPU_USAGE}% usado"
    
    # Disco
    DISK_USAGE=$(df -h / | awk 'NR==2{print $5}')
    info "  - Disco: ${DISK_USAGE} usado"
}

check_connectivity() {
    log "🌐 Verificando conectividade..."
    
    # Local
    if curl -s -o /dev/null "http://localhost:3000/api/health"; then
        log "✅ Aplicação responde localmente"
    else
        alert "❌ Aplicação não responde localmente"
    fi
    
    # Externa
    if [[ -n "$DOMAIN" ]]; then
        RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" --max-time 10)
        if [[ "$RESPONSE_CODE" =~ ^(200|301|302)$ ]]; then
            log "✅ Site acessível externamente ($RESPONSE_CODE)"
        else
            alert "❌ Site não acessível ($RESPONSE_CODE)"
        fi
    fi
}

check_ssl() {
    log "🔒 Verificando SSL..."
    
    if [[ -n "$DOMAIN" ]]; then
        EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates | grep "notAfter" | cut -d= -f2)
        
        if [[ -n "$EXPIRY_DATE" ]]; then
            EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
            CURRENT_TIMESTAMP=$(date +%s)
            DAYS_UNTIL_EXPIRY=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
            
            if [[ "$DAYS_UNTIL_EXPIRY" -lt 30 ]]; then
                alert "⚠️ SSL expira em $DAYS_UNTIL_EXPIRY dias!"
            else
                log "✅ SSL OK (expira em $DAYS_UNTIL_EXPIRY dias)"
            fi
        fi
    fi
}

security_check() {
    log "🔐 Verificação de segurança..."
    
    # Firewall
    if ufw status | grep -q "Status: active"; then
        log "✅ Firewall ativo"
    else
        alert "❌ Firewall inativo!"
    fi
    
    # Fail2ban
    if systemctl is-active --quiet fail2ban; then
        log "✅ Fail2ban ativo"
    else
        alert "❌ Fail2ban inativo!"
    fi
    
    # Logs de segurança
    if [[ -f "/var/log/auth.log" ]]; then
        RECENT_FAILURES=$(grep "Failed password" /var/log/auth.log | tail -10 | wc -l)
        if [[ "$RECENT_FAILURES" -gt 0 ]]; then
            warning "⚠️ $RECENT_FAILURES tentativas de login falhadas recentes"
        else
            log "✅ Nenhuma tentativa de login suspeita"
        fi
    fi
}

generate_report() {
    log "📋 Gerando relatório completo..."
    
    REPORT_FILE="/var/log/novusio-report-$(date +%Y%m%d-%H%M).txt"
    
    cat > "$REPORT_FILE" << EOF
# Relatório do Novusio - $(date)
Servidor: $(hostname)

## Status da Aplicação
$(pm2 list)

## Recursos do Sistema
$(free -h)
$(df -h /)

## Serviços
$(systemctl status nginx --no-pager -l)
$(systemctl status fail2ban --no-pager -l)

## Conectividade
$(curl -s -o /dev/null -w "Site: %{http_code} (%{time_total}s)\n" https://$DOMAIN)

## SSL
$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates)
EOF
    
    info "Relatório salvo em: $REPORT_FILE"
}

# =============================================================================
# COMANDOS DE CONFIGURAÇÃO
# =============================================================================

deploy_app() {
    log "🚀 Executando deploy completo..."
    if [[ -f "$PROJECT_DIR/instalador/deploy.sh" ]]; then
        bash "$PROJECT_DIR/instalador/deploy.sh"
    else
        alert "❌ Script de deploy não encontrado"
    fi
}

show_config() {
    log "⚙️ Configurações atuais:"
    echo ""
    echo "Diretório do projeto: $PROJECT_DIR"
    echo "Nome da aplicação: $APP_NAME"
    echo "Domínio: $DOMAIN"
    echo ""
    echo "Variáveis de ambiente:"
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        grep -v "PASSWORD\|SECRET\|KEY" "$PROJECT_DIR/.env" | head -10
    else
        echo "Arquivo .env não encontrado"
    fi
}

system_info() {
    log "💻 Informações do Sistema:"
    echo "=================================="
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime)"
    echo "Sistema: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo ""
    echo "Recursos:"
    echo "Memória: $(free -h | awk 'NR==2{printf "%.1f%% (%s/%s)", $3*100/$2, $3, $2}')"
    echo "Disco: $(df -h / | awk 'NR==2{printf "%s (%s livres)", $5, $4}')"
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
    echo ""
    echo "Aplicação:"
    pm2 list | grep "$APP_NAME" || echo "Aplicação não encontrada"
}

open_menu() {
    echo -e "${BLUE}🚀 Abrindo menu interativo...${NC}"
    if [[ -f "$PROJECT_DIR/instalador/deploy.sh" ]]; then
        bash "$PROJECT_DIR/instalador/deploy.sh"
    else
        alert "❌ Script de deploy não encontrado"
    fi
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    case "${1:-help}" in
        # Aplicação
        start) check_root; start_app ;;
        stop) check_root; stop_app ;;
        restart) check_root; restart_app ;;
        status) check_root; status_app ;;
        logs) check_root; logs_app ;;
        update) check_root; update_app ;;
        
        # Manutenção
        backup) check_root; backup_manual ;;
        monitor) check_root; monitor_app ;;
        maintenance) check_root; maintenance_app ;;
        cleanup) check_root; cleanup_system ;;
        
        # Serviços
        ssl) check_root; renew_ssl ;;
        nginx) check_root; reload_nginx ;;
        services) check_root; check_services ;;
        
        # Monitoramento
        health) check_root; health_check ;;
        resources) check_root; check_system_resources ;;
        security) check_root; security_check ;;
        report) check_root; generate_report ;;
        
        # Configuração
        deploy) check_root; deploy_app ;;
        config) check_root; show_config ;;
        info) check_root; system_info ;;
        menu) check_root; open_menu ;;
        
        # Ajuda
        help|--help|-h) show_help ;;
        
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
