#!/bin/bash

# =============================================================================
# SCRIPT DE BACKUP AUTOMÁTICO - NOVUSIO
# =============================================================================
# Este script faz backup completo da aplicação incluindo:
# - Banco de dados SQLite
# - Arquivos de upload
# - Configurações
# - Logs importantes
# =============================================================================

set -e

# Configurações
BACKUP_DIR="/opt/backups/novusio"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="/home/novusio"
RETENTION_DAYS=30
LOG_FILE="/var/log/novusio-backup.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função de log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Criar diretório de backup se não existir
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log "Diretório de backup criado: $BACKUP_DIR"
    fi
}

# Backup do banco de dados
backup_database() {
    log "Iniciando backup do banco de dados..."
    
    DB_FILE="$PROJECT_DIR/database.sqlite"
    if [[ -f "$DB_FILE" ]]; then
        # Fazer dump do SQLite
        sqlite3 "$DB_FILE" ".dump" > "$BACKUP_DIR/database_$DATE.sql"
        
        # Copiar arquivo original também
        cp "$DB_FILE" "$BACKUP_DIR/database_$DATE.sqlite"
        
        # Comprimir
        gzip "$BACKUP_DIR/database_$DATE.sql"
        
        log "✓ Backup do banco de dados concluído"
    else
        warning "Arquivo de banco de dados não encontrado: $DB_FILE"
    fi
}

# Backup dos uploads
backup_uploads() {
    log "Iniciando backup dos arquivos de upload..."
    
    UPLOADS_DIR="$PROJECT_DIR/uploads"
    if [[ -d "$UPLOADS_DIR" ]]; then
        tar -czf "$BACKUP_DIR/uploads_$DATE.tar.gz" -C "$PROJECT_DIR" uploads/
        log "✓ Backup dos uploads concluído"
    else
        warning "Diretório de uploads não encontrado: $UPLOADS_DIR"
    fi
}

# Backup das configurações
backup_config() {
    log "Iniciando backup das configurações..."
    
    CONFIG_FILES=(
        ".env"
        "ecosystem.config.js"
        "package.json"
        "package-lock.json"
    )
    
    # Criar diretório temporário para configurações
    TEMP_DIR="/tmp/novusio_config_$DATE"
    mkdir -p "$TEMP_DIR"
    
    # Copiar arquivos de configuração
    for file in "${CONFIG_FILES[@]}"; do
        if [[ -f "$PROJECT_DIR/$file" ]]; then
            cp "$PROJECT_DIR/$file" "$TEMP_DIR/"
            log "✓ Copiado: $file"
        else
            warning "Arquivo não encontrado: $file"
        fi
    done
    
    # Copiar logs importantes (últimos 7 dias)
    if [[ -d "/var/log/novusio" ]]; then
        mkdir -p "$TEMP_DIR/logs"
        find /var/log/novusio -name "*.log" -mtime -7 -exec cp {} "$TEMP_DIR/logs/" \;
        log "✓ Logs copiados"
    fi
    
    # Criar arquivo de informações do sistema
    cat > "$TEMP_DIR/system_info.txt" << EOF
# Informações do Sistema - $(date)
Hostname: $(hostname)
Uptime: $(uptime)
Disk Usage: $(df -h /)
Memory Usage: $(free -h)
Node Version: $(node --version)
NPM Version: $(npm --version)
PM2 Status: $(pm2 list)
EOF
    
    # Comprimir configurações
    tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" -C "/tmp" "novusio_config_$DATE"
    rm -rf "$TEMP_DIR"
    
    log "✓ Backup das configurações concluído"
}

# Backup completo do código (opcional)
backup_source_code() {
    log "Iniciando backup do código fonte..."
    
    # Excluir node_modules e outros arquivos desnecessários
    tar --exclude='node_modules' \
        --exclude='client/node_modules' \
        --exclude='uploads' \
        --exclude='database.sqlite' \
        --exclude='.git' \
        --exclude='*.log' \
        -czf "$BACKUP_DIR/source_$DATE.tar.gz" \
        -C "$PROJECT_DIR" .
    
    log "✓ Backup do código fonte concluído"
}

# Verificar integridade dos backups
verify_backups() {
    log "Verificando integridade dos backups..."
    
    # Verificar arquivos comprimidos
    for file in "$BACKUP_DIR"/*_$DATE.*; do
        if [[ -f "$file" ]]; then
            if [[ "$file" == *.gz ]]; then
                if gzip -t "$file"; then
                    log "✓ Arquivo íntegro: $(basename "$file")"
                else
                    error "❌ Arquivo corrompido: $(basename "$file")"
                fi
            fi
        fi
    done
}

# Limpeza de backups antigos
cleanup_old_backups() {
    log "Removendo backups antigos (mais de $RETENTION_DAYS dias)..."
    
    find "$BACKUP_DIR" -name "*.sqlite" -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    log "✓ Limpeza de backups antigos concluída"
}

# Estatísticas do backup
backup_stats() {
    log "Estatísticas do backup:"
    
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
    BACKUP_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
    
    echo "  - Tamanho total: $BACKUP_SIZE"
    echo "  - Número de arquivos: $BACKUP_COUNT"
    echo "  - Retenção: $RETENTION_DAYS dias"
    
    # Listar arquivos do backup atual
    echo "  - Arquivos do backup atual:"
    for file in "$BACKUP_DIR"/*_$DATE.*; do
        if [[ -f "$file" ]]; then
            size=$(du -h "$file" | cut -f1)
            echo "    * $(basename "$file") ($size)"
        fi
    done
}

# Enviar notificação (opcional)
send_notification() {
    # Aqui você pode adicionar notificações por email, Slack, etc.
    # Exemplo básico:
    log "Backup concluído com sucesso em $(date)"
    
    # Exemplo para Slack (descomente e configure):
    # if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
    #     curl -X POST -H 'Content-type: application/json' \
    #         --data "{\"text\":\"✅ Backup Novusio concluído com sucesso em $(date)\"}" \
    #         "$SLACK_WEBHOOK_URL"
    # fi
}

# Função principal
main() {
    log "🚀 Iniciando backup automático do Novusio"
    
    create_backup_dir
    backup_database
    backup_uploads
    backup_config
    backup_source_code
    verify_backups
    cleanup_old_backups
    backup_stats
    send_notification
    
    log "✅ Backup concluído com sucesso!"
}

# Verificar se está sendo executado como root
if [[ $EUID -ne 0 ]]; then
    error "Este script deve ser executado como root"
fi

# Executar função principal
main "$@"
