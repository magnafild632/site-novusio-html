#!/bin/bash

# =============================================================================
# SCRIPT DE MONITORAMENTO - NOVUSIO
# =============================================================================
# Este script monitora a aplicação e sistema:
# - Status da aplicação PM2
# - Uso de memória e CPU
# - Espaço em disco
# - Conectividade da aplicação
# - Logs de erro
# =============================================================================

set -e

# Configurações
LOG_FILE="/var/log/novusio-monitor.log"
ALERT_LOG="/var/log/novusio-alerts.log"
PROJECT_DIR="/opt/novusio"
APP_NAME="novusio-server"
DOMAIN="novusio.com"  # Substitua pelo seu domínio

# Limites de alerta
MEMORY_THRESHOLD=800  # MB
CPU_THRESHOLD=80      # %
DISK_THRESHOLD=85     # %
RESPONSE_TIME_THRESHOLD=5  # segundos

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Verificar status do PM2
check_pm2_status() {
    log "Verificando status do PM2..."
    
    if ! command -v pm2 &> /dev/null; then
        alert "PM2 não está instalado!"
        return 1
    fi
    
    # Verificar se a aplicação está rodando
    if pm2 list | grep -q "$APP_NAME.*online"; then
        log "✓ Aplicação $APP_NAME está online"
        
        # Obter informações detalhadas
        PM2_INFO=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\")")
        if [[ -n "$PM2_INFO" ]]; then
            CPU_USAGE=$(echo "$PM2_INFO" | jq -r '.monit.cpu')
            MEMORY_USAGE=$(echo "$PM2_INFO" | jq -r '.monit.memory / 1024 / 1024')
            UPTIME=$(echo "$PM2_INFO" | jq -r '.pm2_env.status')
            RESTARTS=$(echo "$PM2_INFO" | jq -r '.pm2_env.restart_time')
            
            info "  - CPU: ${CPU_USAGE}%"
            info "  - Memória: ${MEMORY_USAGE}MB"
            info "  - Status: $UPTIME"
            info "  - Restarts: $RESTARTS"
            
            # Verificar uso de memória
            if (( $(echo "$MEMORY_USAGE > $MEMORY_THRESHOLD" | bc -l) )); then
                alert "⚠️ Uso de memória alto: ${MEMORY_USAGE}MB (limite: ${MEMORY_THRESHOLD}MB)"
            fi
            
            # Verificar uso de CPU
            if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
                alert "⚠️ Uso de CPU alto: ${CPU_USAGE}% (limite: ${CPU_THRESHOLD}%)"
            fi
            
            # Verificar muitos restarts
            if [[ "$RESTARTS" -gt 10 ]]; then
                alert "⚠️ Muitos restarts detectados: $RESTARTS"
            fi
        fi
    else
        alert "❌ Aplicação $APP_NAME não está rodando!"
        log "Tentando reiniciar a aplicação..."
        
        cd "$PROJECT_DIR"
        if pm2 restart "$APP_NAME"; then
            log "✓ Aplicação reiniciada com sucesso"
        else
            alert "❌ Falha ao reiniciar a aplicação"
            return 1
        fi
    fi
}

# Verificar uso de recursos do sistema
check_system_resources() {
    log "Verificando recursos do sistema..."
    
    # Uso de memória
    MEMORY_INFO=$(free -m)
    MEMORY_USED=$(echo "$MEMORY_INFO" | awk 'NR==2{printf "%.1f", $3*100/$2}')
    MEMORY_TOTAL=$(echo "$MEMORY_INFO" | awk 'NR==2{printf "%.0f", $2}')
    MEMORY_FREE=$(echo "$MEMORY_INFO" | awk 'NR==2{printf "%.0f", $4}')
    
    info "  - Memória: ${MEMORY_USED}% usado (${MEMORY_FREE}MB livre de ${MEMORY_TOTAL}MB)"
    
    if (( $(echo "$MEMORY_USED > 90" | bc -l) )); then
        alert "⚠️ Uso de memória do sistema crítico: ${MEMORY_USED}%"
    fi
    
    # Uso de CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    info "  - CPU: ${CPU_USAGE}% usado"
    
    if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
        alert "⚠️ Uso de CPU alto: ${CPU_USAGE}%"
    fi
    
    # Espaço em disco
    DISK_INFO=$(df -h /)
    DISK_USAGE=$(echo "$DISK_INFO" | awk 'NR==2 {print $5}' | sed 's/%//')
    DISK_AVAILABLE=$(echo "$DISK_INFO" | awk 'NR==2 {print $4}')
    
    info "  - Disco: ${DISK_USAGE}% usado (${DISK_AVAILABLE} disponível)"
    
    if [[ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]]; then
        alert "⚠️ Espaço em disco baixo: ${DISK_USAGE}% (limite: ${DISK_THRESHOLD}%)"
        
        # Mostrar os maiores diretórios
        info "Maiores diretórios em /:"
        du -h / 2>/dev/null | sort -hr | head -5 | while read size dir; do
            info "  - $size $dir"
        done
    fi
}

# Verificar conectividade da aplicação
check_application_connectivity() {
    log "Verificando conectividade da aplicação..."
    
    # Verificar se a aplicação responde localmente
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/health" | grep -q "200"; then
        log "✓ Aplicação responde localmente"
    else
        alert "❌ Aplicação não responde localmente"
        return 1
    fi
    
    # Verificar se o site está acessível externamente
    if [[ -n "$DOMAIN" ]]; then
        RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" --max-time 10)
        RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" "https://$DOMAIN" --max-time 10)
        
        if [[ "$RESPONSE_CODE" =~ ^(200|301|302)$ ]]; then
            log "✓ Site acessível externamente (${RESPONSE_CODE})"
            info "  - Tempo de resposta: ${RESPONSE_TIME}s"
            
            # Verificar tempo de resposta
            if (( $(echo "$RESPONSE_TIME > $RESPONSE_TIME_THRESHOLD" | bc -l) )); then
                alert "⚠️ Tempo de resposta alto: ${RESPONSE_TIME}s (limite: ${RESPONSE_TIME_THRESHOLD}s)"
            fi
        else
            alert "❌ Site não acessível externamente (código: $RESPONSE_CODE)"
        fi
    fi
}

# Verificar logs de erro
check_error_logs() {
    log "Verificando logs de erro..."
    
    # Verificar logs do PM2
    if [[ -f "/var/log/novusio/error.log" ]]; then
        ERROR_COUNT=$(tail -100 /var/log/novusio/error.log | grep -c "ERROR\|error" || true)
        if [[ "$ERROR_COUNT" -gt 0 ]]; then
            warning "⚠️ $ERROR_COUNT erros encontrados nos últimos logs"
            
            # Mostrar últimos erros
            info "Últimos erros:"
            tail -100 /var/log/novusio/error.log | grep "ERROR\|error" | tail -3 | while read line; do
                info "  - $line"
            done
        else
            log "✓ Nenhum erro recente nos logs"
        fi
    fi
    
    # Verificar logs do Nginx
    if [[ -f "/var/log/nginx/error.log" ]]; then
        NGINX_ERRORS=$(tail -100 /var/log/nginx/error.log | grep -c "error" || true)
        if [[ "$NGINX_ERRORS" -gt 0 ]]; then
            warning "⚠️ $NGINX_ERRORS erros encontrados nos logs do Nginx"
        fi
    fi
}

# Verificar certificado SSL
check_ssl_certificate() {
    log "Verificando certificado SSL..."
    
    if [[ -n "$DOMAIN" ]]; then
        # Verificar data de expiração do certificado
        EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates | grep "notAfter" | cut -d= -f2)
        
        if [[ -n "$EXPIRY_DATE" ]]; then
            EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
            CURRENT_TIMESTAMP=$(date +%s)
            DAYS_UNTIL_EXPIRY=$(( (EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400 ))
            
            info "  - Certificado expira em $DAYS_UNTIL_EXPIRY dias"
            
            if [[ "$DAYS_UNTIL_EXPIRY" -lt 30 ]]; then
                alert "⚠️ Certificado SSL expira em $DAYS_UNTIL_EXPIRY dias!"
            elif [[ "$DAYS_UNTIL_EXPIRY" -lt 7 ]]; then
                alert "❌ Certificado SSL expira em $DAYS_UNTIL_EXPIRY dias - RENOVAÇÃO URGENTE!"
            fi
        else
            alert "❌ Não foi possível verificar o certificado SSL"
        fi
    fi
}

# Verificar serviços essenciais
check_essential_services() {
    log "Verificando serviços essenciais..."
    
    SERVICES=("nginx" "fail2ban")
    
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "✓ $service está ativo"
        else
            alert "❌ $service não está ativo"
            
            # Tentar iniciar o serviço
            if systemctl start "$service"; then
                log "✓ $service iniciado com sucesso"
            else
                alert "❌ Falha ao iniciar $service"
            fi
        fi
    done
}

# Verificar firewall
check_firewall() {
    log "Verificando firewall..."
    
    if ufw status | grep -q "Status: active"; then
        log "✓ Firewall UFW está ativo"
        
        # Verificar regras básicas
        if ufw status | grep -q "80/tcp"; then
            log "✓ Porta 80 (HTTP) liberada"
        else
            warning "⚠️ Porta 80 não está liberada no firewall"
        fi
        
        if ufw status | grep -q "443/tcp"; then
            log "✓ Porta 443 (HTTPS) liberada"
        else
            warning "⚠️ Porta 443 não está liberada no firewall"
        fi
    else
        alert "❌ Firewall UFW não está ativo!"
    fi
}

# Verificar backup
check_backup() {
    log "Verificando status do backup..."
    
    BACKUP_DIR="/opt/backups/novusio"
    if [[ -d "$BACKUP_DIR" ]]; then
        BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*.sqlite" -mtime -1 | wc -l)
        if [[ "$BACKUP_COUNT" -gt 0 ]]; then
            log "✓ Backup recente encontrado ($BACKUP_COUNT arquivos)"
        else
            warning "⚠️ Nenhum backup recente encontrado"
        fi
    else
        warning "⚠️ Diretório de backup não existe"
    fi
}

# Gerar relatório
generate_report() {
    log "Gerando relatório de monitoramento..."
    
    REPORT_FILE="/var/log/novusio-monitor-report-$(date +%Y%m%d).txt"
    
    cat > "$REPORT_FILE" << EOF
# Relatório de Monitoramento - Novusio
Data: $(date)
Servidor: $(hostname)

## Status da Aplicação
$(pm2 list)

## Recursos do Sistema
$(free -h)
$(df -h /)

## Status dos Serviços
$(systemctl status nginx --no-pager -l)
$(systemctl status fail2ban --no-pager -l)

## Logs Recentes
$(tail -20 /var/log/novusio/error.log 2>/dev/null || echo "Nenhum log de erro encontrado")

## Estatísticas de Tráfego (últimas 24h)
$(tail -100 /var/log/nginx/access.log 2>/dev/null | wc -l) requisições
EOF
    
    info "Relatório salvo em: $REPORT_FILE"
}

# Enviar alertas (opcional)
send_alerts() {
    if [[ -f "$ALERT_LOG" ]] && [[ -s "$ALERT_LOG" ]]; then
        # Verificar se há alertas novos (última hora)
        RECENT_ALERTS=$(tail -100 "$ALERT_LOG" | grep "$(date +'%Y-%m-%d %H')" | wc -l)
        
        if [[ "$RECENT_ALERTS" -gt 0 ]]; then
            warning "⚠️ $RECENT_ALERTS alertas gerados na última hora"
            
            # Aqui você pode adicionar notificações por email, Slack, etc.
            # Exemplo para Slack (descomente e configure):
            # if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
            #     curl -X POST -H 'Content-type: application/json' \
            #         --data "{\"text\":\"⚠️ $RECENT_ALERTS alertas no servidor $(hostname)\"}" \
            #         "$SLACK_WEBHOOK_URL"
            # fi
        fi
    fi
}

# Função principal
main() {
    log "🔍 Iniciando monitoramento do Novusio"
    
    check_pm2_status
    check_system_resources
    check_application_connectivity
    check_error_logs
    check_ssl_certificate
    check_essential_services
    check_firewall
    check_backup
    generate_report
    send_alerts
    
    log "✅ Monitoramento concluído"
}

# Verificar se está sendo executado como root
if [[ $EUID -ne 0 ]]; then
    error "Este script deve ser executado como root"
fi

# Executar função principal
main "$@"
