#!/bin/bash

# =============================================================================
# Menu Principal - Site Novusio
# Sistema de gerenciamento do deploy
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

# Configurações padrão
PROJECT_PATH="/home/$(whoami)/site-novusio"
SERVICE_NAME="novusio"
NGINX_CONFIG="/etc/nginx/sites-available/novusio"

# Função para exibir banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║              🎛️  MENU NOVUSIO MANAGER 🎛️                   ║"
    echo "║                                                              ║"
    echo "║              Sistema de Gerenciamento do Deploy              ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

# Verificar se o projeto está instalado
check_installation() {
    if [[ ! -d "$PROJECT_PATH" ]]; then
        error "Projeto não encontrado em $PROJECT_PATH"
        error "Execute primeiro o script deploy.sh para instalar o projeto."
        exit 1
    fi
}

# Verificar se é root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Este script não deve ser executado como root!"
        exit 1
    fi
}

# Mostrar status do sistema
show_status() {
    clear
    echo -e "${CYAN}📊 Status do Sistema${NC}"
    echo -e "${YELLOW}===================${NC}"
    echo ""
    
    # Status do serviço
    echo -e "${BLUE}🔧 Serviço Novusio:${NC}"
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "   Status: ${GREEN}✅ Rodando${NC}"
    else
        echo -e "   Status: ${RED}❌ Parado${NC}"
    fi
    
    # Status do Nginx
    echo -e "${BLUE}🌐 Nginx:${NC}"
    if sudo systemctl is-active --quiet nginx; then
        echo -e "   Status: ${GREEN}✅ Rodando${NC}"
    else
        echo -e "   Status: ${RED}❌ Parado${NC}"
    fi
    
    # Status do SSL
    echo -e "${BLUE}🔒 SSL:${NC}"
    if sudo certbot certificates 2>/dev/null | grep -q "Certificate Name"; then
        echo -e "   Status: ${GREEN}✅ Configurado${NC}"
    else
        echo -e "   Status: ${YELLOW}⚠️  Não configurado${NC}"
    fi
    
    # Status do banco de dados
    echo -e "${BLUE}🗄️  Banco de Dados:${NC}"
    if [[ -f "$PROJECT_PATH/database.sqlite" ]]; then
        echo -e "   Status: ${GREEN}✅ Existe${NC}"
    else
        echo -e "   Status: ${RED}❌ Não encontrado${NC}"
    fi
    
    # Uso de disco
    echo -e "${BLUE}💾 Uso de Disco:${NC}"
    echo -e "   Projeto: $(du -sh "$PROJECT_PATH" 2>/dev/null | cut -f1 || echo 'N/A')"
    
    # Logs recentes
    echo -e "${BLUE}📝 Logs Recentes:${NC}"
    sudo journalctl -u "$SERVICE_NAME" --since "1 hour ago" --no-pager | tail -3 | sed 's/^/   /'
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Instalar projeto
install_project() {
    clear
    echo -e "${CYAN}🚀 Instalação do Projeto${NC}"
    echo -e "${YELLOW}=========================${NC}"
    echo ""
    
    if [[ -d "$PROJECT_PATH" ]]; then
        warning "Projeto já existe em $PROJECT_PATH"
        read -p "Deseja reinstalar? Isso removerá todos os dados! (y/N): " REINSTALL
        if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
            info "Instalação cancelada."
            return
        fi
    fi
    
    # Executar script de deploy
    if [[ -f "deploy.sh" ]]; then
        chmod +x deploy.sh
        ./deploy.sh
    else
        error "Script deploy.sh não encontrado!"
        error "Certifique-se de estar na pasta instalador/"
        exit 1
    fi
}

# Atualizar projeto
update_project() {
    clear
    echo -e "${CYAN}🔄 Atualização do Projeto${NC}"
    echo -e "${YELLOW}=========================${NC}"
    echo ""
    
    check_installation
    
    # Fazer backup do banco de dados
    if [[ -f "$PROJECT_PATH/database.sqlite" ]]; then
        log "Fazendo backup do banco de dados..."
        cp "$PROJECT_PATH/database.sqlite" "$PROJECT_PATH/database.sqlite.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Parar serviço
    log "Parando serviço..."
    sudo systemctl stop "$SERVICE_NAME"
    
    # Fazer backup do .env
    if [[ -f "$PROJECT_PATH/.env" ]]; then
        cp "$PROJECT_PATH/.env" "$PROJECT_PATH/.env.backup"
    fi
    
    # Atualizar código
    log "Atualizando código do repositório..."
    cd "$PROJECT_PATH"
    
    # Salvar mudanças locais se houver
    if git status --porcelain | grep -q .; then
        warning "Existem mudanças locais não commitadas."
        read -p "Deseja salvar as mudanças em um stash? (y/N): " STASH
        if [[ "$STASH" =~ ^[Yy]$ ]]; then
            git stash push -m "Backup antes da atualização $(date)"
        fi
    fi
    
    # Fazer pull
    git fetch origin
    git reset --hard origin/main
    
    # Restaurar .env
    if [[ -f "$PROJECT_PATH/.env.backup" ]]; then
        mv "$PROJECT_PATH/.env.backup" "$PROJECT_PATH/.env"
    fi
    
    # Atualizar dependências
    log "Atualizando dependências do servidor..."
    npm install
    
    log "Atualizando dependências do cliente..."
    cd "$PROJECT_PATH/client"
    npm install
    
    # Rebuild do projeto
    log "Reconstruindo projeto React..."
    cd "$PROJECT_PATH"
    npm run build
    
    # Reiniciar serviço
    log "Reiniciando serviço..."
    sudo systemctl start "$SERVICE_NAME"
    
    # Verificar status
    sleep 3
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        log "✅ Projeto atualizado com sucesso!"
    else
        error "❌ Erro ao reiniciar o serviço"
        sudo systemctl status "$SERVICE_NAME"
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Remover projeto
remove_project() {
    clear
    echo -e "${CYAN}🗑️  Remoção do Projeto${NC}"
    echo -e "${YELLOW}======================${NC}"
    echo ""
    
    warning "ATENÇÃO: Esta ação irá remover completamente o projeto e todos os dados!"
    echo ""
    echo "O que será removido:"
    echo "- Diretório do projeto: $PROJECT_PATH"
    echo "- Serviço systemd: $SERVICE_NAME"
    echo "- Configuração Nginx"
    echo "- Certificados SSL (opcional)"
    echo ""
    
    read -p "Tem certeza que deseja continuar? Digite 'REMOVER' para confirmar: " CONFIRM
    
    if [[ "$CONFIRM" != "REMOVER" ]]; then
        info "Remoção cancelada."
        return
    fi
    
    # Parar e remover serviço
    log "Parando e removendo serviço..."
    sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    sudo rm -f "/etc/systemd/system/$SERVICE_NAME.service"
    sudo systemctl daemon-reload
    
    # Remover configuração Nginx
    log "Removendo configuração Nginx..."
    sudo rm -f "/etc/nginx/sites-enabled/novusio"
    sudo rm -f "/etc/nginx/sites-available/novusio"
    sudo systemctl reload nginx
    
    # Perguntar sobre SSL
    read -p "Deseja remover os certificados SSL? (y/N): " REMOVE_SSL
    if [[ "$REMOVE_SSL" =~ ^[Yy]$ ]]; then
        log "Removendo certificados SSL..."
        sudo certbot delete --cert-name "$(hostname)" --non-interactive 2>/dev/null || true
    fi
    
    # Remover diretório do projeto
    log "Removendo diretório do projeto..."
    sudo rm -rf "$PROJECT_PATH"
    
    # Remover logs
    log "Removendo logs..."
    sudo rm -f "/var/log/nginx/novusio_*.log"
    
    log "✅ Projeto removido com sucesso!"
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Gerenciar logs
manage_logs() {
    clear
    echo -e "${CYAN}📝 Gerenciamento de Logs${NC}"
    echo -e "${YELLOW}========================${NC}"
    echo ""
    
    while true; do
        echo "1. Ver logs do serviço (últimas 50 linhas)"
        echo "2. Ver logs do serviço em tempo real"
        echo "3. Ver logs do Nginx"
        echo "4. Ver logs de erro do Nginx"
        echo "5. Limpar logs antigos"
        echo "0. Voltar ao menu principal"
        echo ""
        read -p "Escolha uma opção: " LOG_OPTION
        
        case $LOG_OPTION in
            1)
                clear
                echo -e "${BLUE}Logs do serviço (últimas 50 linhas):${NC}"
                sudo journalctl -u "$SERVICE_NAME" --no-pager -n 50
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            2)
                clear
                echo -e "${BLUE}Logs do serviço em tempo real (Ctrl+C para sair):${NC}"
                sudo journalctl -u "$SERVICE_NAME" -f
                ;;
            3)
                clear
                echo -e "${BLUE}Logs do Nginx:${NC}"
                sudo tail -50 /var/log/nginx/novusio_access.log 2>/dev/null || echo "Arquivo de log não encontrado"
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            4)
                clear
                echo -e "${BLUE}Logs de erro do Nginx:${NC}"
                sudo tail -50 /var/log/nginx/novusio_error.log 2>/dev/null || echo "Arquivo de log não encontrado"
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            5)
                clear
                echo -e "${BLUE}Limpando logs antigos...${NC}"
                sudo journalctl --vacuum-time=7d
                sudo find /var/log -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true
                log "Logs antigos removidos!"
                echo ""
                read -p "Pressione Enter para continuar..."
                ;;
            0)
                break
                ;;
            *)
                error "Opção inválida!"
                ;;
        esac
        clear
        echo -e "${CYAN}📝 Gerenciamento de Logs${NC}"
        echo -e "${YELLOW}========================${NC}"
        echo ""
    done
}

# Backup do projeto
backup_project() {
    clear
    echo -e "${CYAN}💾 Backup do Projeto${NC}"
    echo -e "${YELLOW}====================${NC}"
    echo ""
    
    check_installation
    
    BACKUP_DIR="/home/$(whoami)/backups"
    BACKUP_FILE="novusio_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Criar diretório de backup
    mkdir -p "$BACKUP_DIR"
    
    log "Criando backup do projeto..."
    
    # Criar backup
    cd "$PROJECT_PATH/.."
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" \
        --exclude="node_modules" \
        --exclude="client/node_modules" \
        --exclude="client/dist" \
        --exclude=".git" \
        site-novusio/
    
    # Verificar se o backup foi criado
    if [[ -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
        log "✅ Backup criado com sucesso: $BACKUP_DIR/$BACKUP_FILE"
        echo "Tamanho: $(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)"
    else
        error "❌ Erro ao criar backup"
        return 1
    fi
    
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Restaurar backup
restore_backup() {
    clear
    echo -e "${CYAN}🔄 Restaurar Backup${NC}"
    echo -e "${YELLOW}==================${NC}"
    echo ""
    
    BACKUP_DIR="/home/$(whoami)/backups"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        error "Diretório de backups não encontrado: $BACKUP_DIR"
        return 1
    fi
    
    # Listar backups disponíveis
    echo "Backups disponíveis:"
    ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null || {
        error "Nenhum backup encontrado!"
        return 1
    }
    echo ""
    
    read -p "Digite o nome do arquivo de backup: " BACKUP_FILE
    
    if [[ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
        error "Arquivo de backup não encontrado: $BACKUP_DIR/$BACKUP_FILE"
        return 1
    fi
    
    warning "ATENÇÃO: Esta ação irá substituir o projeto atual!"
    read -p "Tem certeza que deseja continuar? (y/N): " CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        info "Restauração cancelada."
        return
    fi
    
    # Parar serviço
    log "Parando serviço..."
    sudo systemctl stop "$SERVICE_NAME"
    
    # Fazer backup do estado atual
    if [[ -d "$PROJECT_PATH" ]]; then
        mv "$PROJECT_PATH" "$PROJECT_PATH.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Restaurar backup
    log "Restaurando backup..."
    cd "/home/$(whoami)"
    tar -xzf "$BACKUP_DIR/$BACKUP_FILE"
    
    # Reinstalar dependências
    log "Reinstalando dependências..."
    cd "$PROJECT_PATH"
    npm install
    cd "$PROJECT_PATH/client"
    npm install
    
    # Rebuild do projeto
    log "Reconstruindo projeto..."
    cd "$PROJECT_PATH"
    npm run build
    
    # Reiniciar serviço
    log "Reiniciando serviço..."
    sudo systemctl start "$SERVICE_NAME"
    
    log "✅ Backup restaurado com sucesso!"
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Menu principal
main_menu() {
    while true; do
        show_banner
        
        echo -e "${CYAN}Escolha uma opção:${NC}"
        echo ""
        echo "1. 🚀 Instalar Projeto"
        echo "2. 🔄 Atualizar Projeto"
        echo "3. 📊 Ver Status do Sistema"
        echo "4. 📝 Gerenciar Logs"
        echo "5. 💾 Backup do Projeto"
        echo "6. 🔄 Restaurar Backup"
        echo "7. 🗑️  Remover Projeto"
        echo "0. 🚪 Sair"
        echo ""
        read -p "Digite sua opção: " OPTION
        
        case $OPTION in
            1)
                install_project
                ;;
            2)
                update_project
                ;;
            3)
                show_status
                ;;
            4)
                manage_logs
                ;;
            5)
                backup_project
                ;;
            6)
                restore_backup
                ;;
            7)
                remove_project
                ;;
            0)
                echo ""
                log "Saindo do menu..."
                exit 0
                ;;
            *)
                error "Opção inválida! Tente novamente."
                sleep 2
                ;;
        esac
    done
}

# Verificações iniciais
check_root

# Executar menu principal
main_menu
