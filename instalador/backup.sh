#!/bin/bash

# =============================================================================
# Script de Backup - Site Novusio
# Sistema completo de backup com compressão e limpeza automática
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
BACKUP_DIR="/home/$(whoami)/backups"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="novusio_backup_$TIMESTAMP"

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

# Verificar se o projeto existe
check_project() {
    if [[ ! -d "$PROJECT_PATH" ]]; then
        error "Projeto não encontrado em $PROJECT_PATH"
        error "Execute o deploy primeiro ou ajuste o caminho no script."
        exit 1
    fi
}

# Criar diretório de backup
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log "Criando diretório de backup: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
}

# Fazer backup do banco de dados
backup_database() {
    log "Fazendo backup do banco de dados..."
    
    if [[ -f "$PROJECT_PATH/database.sqlite" ]]; then
        cp "$PROJECT_PATH/database.sqlite" "$BACKUP_DIR/database_$TIMESTAMP.sqlite"
        log "✅ Banco de dados copiado"
    else
        warning "Banco de dados não encontrado: $PROJECT_PATH/database.sqlite"
    fi
}

# Fazer backup dos arquivos de configuração
backup_configs() {
    log "Fazendo backup dos arquivos de configuração..."
    
    # Backup do .env
    if [[ -f "$PROJECT_PATH/.env" ]]; then
        cp "$PROJECT_PATH/.env" "$BACKUP_DIR/env_$TIMESTAMP"
        log "✅ Arquivo .env copiado"
    fi
    
    # Backup da configuração Nginx
    if [[ -f "/etc/nginx/sites-available/novusio" ]]; then
        sudo cp "/etc/nginx/sites-available/novusio" "$BACKUP_DIR/nginx_$TIMESTAMP.conf"
        log "✅ Configuração Nginx copiada"
    fi
    
    # Backup do serviço systemd
    if [[ -f "/etc/systemd/system/novusio.service" ]]; then
        sudo cp "/etc/systemd/system/novusio.service" "$BACKUP_DIR/novusio_$TIMESTAMP.service"
        log "✅ Serviço systemd copiado"
    fi
}

# Fazer backup dos uploads
backup_uploads() {
    log "Fazendo backup dos uploads..."
    
    if [[ -d "$PROJECT_PATH/client/uploads" ]]; then
        tar -czf "$BACKUP_DIR/uploads_$TIMESTAMP.tar.gz" -C "$PROJECT_PATH/client" uploads/
        log "✅ Uploads comprimidos"
    else
        warning "Diretório de uploads não encontrado: $PROJECT_PATH/client/uploads"
    fi
}

# Fazer backup completo do projeto
backup_project() {
    log "Fazendo backup completo do projeto..."
    
    cd "$PROJECT_PATH/.."
    
    # Criar backup completo (excluindo node_modules e arquivos desnecessários)
    tar -czf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" \
        --exclude="node_modules" \
        --exclude="client/node_modules" \
        --exclude="client/dist" \
        --exclude=".git" \
        --exclude="*.log" \
        --exclude="*.tmp" \
        --exclude="*.swp" \
        --exclude=".DS_Store" \
        site-novusio/
    
    log "✅ Backup completo criado: ${BACKUP_NAME}.tar.gz"
}

# Verificar integridade do backup
verify_backup() {
    log "Verificando integridade do backup..."
    
    BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    
    if [[ -f "$BACKUP_FILE" ]]; then
        # Verificar se o arquivo não está corrompido
        if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
            log "✅ Backup verificado e íntegro"
            echo "Tamanho: $(du -h "$BACKUP_FILE" | cut -f1)"
        else
            error "❌ Backup corrompido!"
            rm -f "$BACKUP_FILE"
            exit 1
        fi
    else
        error "❌ Arquivo de backup não encontrado!"
        exit 1
    fi
}

# Limpar backups antigos
cleanup_old_backups() {
    log "Limpando backups antigos (mais de $RETENTION_DAYS dias)..."
    
    # Contar backups antes da limpeza
    BACKUPS_BEFORE=$(find "$BACKUP_DIR" -name "novusio_backup_*.tar.gz" | wc -l)
    
    # Remover backups antigos
    find "$BACKUP_DIR" -name "novusio_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "database_*.sqlite" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "env_*" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "nginx_*.conf" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "novusio_*.service" -type f -mtime +$RETENTION_DAYS -delete
    find "$BACKUP_DIR" -name "uploads_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
    
    # Contar backups após a limpeza
    BACKUPS_AFTER=$(find "$BACKUP_DIR" -name "novusio_backup_*.tar.gz" | wc -l)
    
    log "✅ Limpeza concluída. Backups: $BACKUPS_BEFORE → $BACKUPS_AFTER"
}

# Criar arquivo de informações do backup
create_backup_info() {
    log "Criando arquivo de informações do backup..."
    
    INFO_FILE="$BACKUP_DIR/${BACKUP_NAME}_info.txt"
    
    cat > "$INFO_FILE" << EOF
# =============================================================================
# Informações do Backup - Site Novusio
# =============================================================================

Data/Hora: $(date)
Versão do Sistema: $(uname -a)
Usuário: $(whoami)
Diretório do Projeto: $PROJECT_PATH
Diretório de Backup: $BACKUP_DIR

# =============================================================================
# Arquivos Incluídos no Backup
# =============================================================================

- Código fonte completo (excluindo node_modules)
- Banco de dados SQLite
- Arquivo de configuração .env
- Uploads de usuários
- Configurações do Nginx
- Configuração do serviço systemd

# =============================================================================
# Como Restaurar
# =============================================================================

1. Parar o serviço:
   sudo systemctl stop novusio

2. Fazer backup do estado atual:
   mv $PROJECT_PATH $PROJECT_PATH.backup.\$(date +%Y%m%d_%H%M%S)

3. Extrair o backup:
   cd /home/$(whoami)
   tar -xzf $BACKUP_DIR/${BACKUP_NAME}.tar.gz

4. Restaurar configurações:
   sudo cp $BACKUP_DIR/nginx_$TIMESTAMP.conf /etc/nginx/sites-available/novusio
   sudo cp $BACKUP_DIR/novusio_$TIMESTAMP.service /etc/systemd/system/novusio.service

5. Reinstalar dependências:
   cd $PROJECT_PATH
   npm install
   cd client && npm install

6. Rebuild do projeto:
   cd $PROJECT_PATH
   npm run build

7. Reiniciar serviços:
   sudo systemctl daemon-reload
   sudo systemctl start novusio
   sudo systemctl reload nginx

# =============================================================================
# Verificação
# =============================================================================

- Verificar status: sudo systemctl status novusio
- Verificar logs: sudo journalctl -u novusio -f
- Testar site: curl -I http://localhost:3000

EOF

    log "✅ Arquivo de informações criado: ${BACKUP_NAME}_info.txt"
}

# Mostrar estatísticas do backup
show_backup_stats() {
    log "Estatísticas do backup:"
    
    BACKUP_FILE="$BACKUP_DIR/${BACKUP_NAME}.tar.gz"
    
    if [[ -f "$BACKUP_FILE" ]]; then
        echo ""
        echo -e "${CYAN}📊 Estatísticas do Backup:${NC}"
        echo -e "${YELLOW}=========================${NC}"
        echo "📁 Arquivo: $(basename "$BACKUP_FILE")"
        echo "💾 Tamanho: $(du -h "$BACKUP_FILE" | cut -f1)"
        echo "📅 Data: $(date -r "$BACKUP_FILE" '+%Y-%m-%d %H:%M:%S')"
        echo "🗂️  Diretório: $BACKUP_DIR"
        echo ""
        
        # Mostrar espaço usado pelos backups
        BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
        echo "💾 Espaço total usado pelos backups: $BACKUP_SIZE"
        
        # Contar número de backups
        BACKUP_COUNT=$(find "$BACKUP_DIR" -name "novusio_backup_*.tar.gz" | wc -l)
        echo "📦 Número de backups: $BACKUP_COUNT"
    fi
}

# Função principal
main() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              💾 BACKUP SITE NOVUSIO 💾                      ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_project
    create_backup_dir
    backup_database
    backup_configs
    backup_uploads
    backup_project
    verify_backup
    create_backup_info
    cleanup_old_backups
    show_backup_stats
    
    echo ""
    log "✅ Backup concluído com sucesso!"
    echo -e "${GREEN}🎉 Todos os dados foram salvos em: $BACKUP_DIR${NC}"
}

# Verificar argumentos
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Uso: $0 [opções]"
    echo ""
    echo "Opções:"
    echo "  --help, -h     Mostrar esta ajuda"
    echo "  --auto         Executar em modo automático (sem interação)"
    echo "  --retention N  Definir dias de retenção (padrão: 30)"
    echo ""
    echo "Exemplos:"
    echo "  $0                    # Backup interativo"
    echo "  $0 --auto            # Backup automático"
    echo "  $0 --retention 7     # Manter backups por 7 dias"
    exit 0
fi

if [[ "$1" == "--retention" && -n "$2" ]]; then
    RETENTION_DAYS="$2"
fi

# Executar função principal
main "$@"
