#!/bin/bash

# 🔧 Gerenciador de Configurações - Site Novusio
# Script para salvar e carregar configurações persistentes

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Caminho do arquivo de configuração
CONFIG_FILE="/opt/novusio/config.conf"

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

# Função para carregar configuração
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        print_success "Configuração carregada de $CONFIG_FILE"
        return 0
    else
        print_warning "Arquivo de configuração não encontrado: $CONFIG_FILE"
        return 1
    fi
}

# Função para salvar configuração
save_config() {
    local config_content=""
    
    # Configurações básicas
    config_content+="# 🔧 Configuração Persistente - Site Novusio\n"
    config_content+="# Gerado em $(date)\n\n"
    
    # Configurações do Domínio
    config_content+="# Configurações do Domínio\n"
    config_content+="DOMAIN=\"${DOMAIN:-}\"\n"
    config_content+="EMAIL=\"${EMAIL:-}\"\n\n"
    
    # Configurações do Git
    config_content+="# Configurações do Git\n"
    config_content+="GIT_REPOSITORY=\"${GIT_REPOSITORY:-}\"\n"
    config_content+="GIT_BRANCH=\"${GIT_BRANCH:-main}\"\n"
    config_content+="GIT_USERNAME=\"${GIT_USERNAME:-}\"\n"
    config_content+="GIT_TOKEN=\"${GIT_TOKEN:-}\"\n\n"
    
    # Configurações do Servidor
    config_content+="# Configurações do Servidor\n"
    config_content+="SERVER_IP=\"${SERVER_IP:-}\"\n"
    config_content+="SERVER_NAME=\"${SERVER_NAME:-}\"\n\n"
    
    # Configurações de Deploy
    config_content+="# Configurações de Deploy\n"
    config_content+="DEPLOY_METHOD=\"${DEPLOY_METHOD:-git}\"\n"
    config_content+="BACKUP_ENABLED=\"${BACKUP_ENABLED:-true}\"\n"
    config_content+="AUTO_UPDATE=\"${AUTO_UPDATE:-false}\"\n\n"
    
    # Configurações de SSL
    config_content+="# Configurações de SSL\n"
    config_content+="SSL_AUTO_RENEW=\"${SSL_AUTO_RENEW:-true}\"\n"
    config_content+="SSL_EMAIL=\"${SSL_EMAIL:-}\"\n\n"
    
    # Configurações de Backup
    config_content+="# Configurações de Backup\n"
    config_content+="BACKUP_SCHEDULE=\"${BACKUP_SCHEDULE:-0 2 * * *}\"\n"
    config_content+="BACKUP_RETENTION_DAYS=\"${BACKUP_RETENTION_DAYS:-30}\"\n\n"
    
    # Configurações de Monitoramento
    config_content+="# Configurações de Monitoramento\n"
    config_content+="MONITORING_ENABLED=\"${MONITORING_ENABLED:-true}\"\n"
    config_content+="ALERT_EMAIL=\"${ALERT_EMAIL:-}\"\n\n"
    
    # Configurações de Performance
    config_content+="# Configurações de Performance\n"
    config_content+="NODE_ENV=\"${NODE_ENV:-production}\"\n"
    config_content+="PORT=\"${PORT:-3000}\"\n"
    config_content+="WORKER_PROCESSES=\"${WORKER_PROCESSES:-1}\"\n\n"
    
    # Configurações de Segurança
    config_content+="# Configurações de Segurança\n"
    config_content+="FAIL2BAN_ENABLED=\"${FAIL2BAN_ENABLED:-true}\"\n"
    config_content+="UFW_ENABLED=\"${UFW_ENABLED:-true}\"\n"
    config_content+="FIREWALL_PORTS=\"${FIREWALL_PORTS:-22,80,443}\"\n\n"
    
    # Configurações de Logs
    config_content+="# Configurações de Logs\n"
    config_content+="LOG_LEVEL=\"${LOG_LEVEL:-info}\"\n"
    config_content+="LOG_ROTATION=\"${LOG_ROTATION:-daily}\"\n"
    config_content+="LOG_RETENTION_DAYS=\"${LOG_RETENTION_DAYS:-7}\"\n\n"
    
    # Configurações de Cache
    config_content+="# Configurações de Cache\n"
    config_content+="CACHE_ENABLED=\"${CACHE_ENABLED:-true}\"\n"
    config_content+="CACHE_TTL=\"${CACHE_TTL:-3600}\"\n\n"
    
    # Configurações de Database
    config_content+="# Configurações de Database\n"
    config_content+="DB_TYPE=\"${DB_TYPE:-sqlite}\"\n"
    config_content+="DB_PATH=\"${DB_PATH:-/opt/novusio/app/database.sqlite}\"\n\n"
    
    # Configurações de Upload
    config_content+="# Configurações de Upload\n"
    config_content+="MAX_FILE_SIZE=\"${MAX_FILE_SIZE:-52428800}\"\n"
    config_content+="UPLOAD_PATH=\"${UPLOAD_PATH:-/opt/novusio/app/client/uploads}\"\n\n"
    
    # Configurações de API
    config_content+="# Configurações de API\n"
    config_content+="API_RATE_LIMIT=\"${API_RATE_LIMIT:-100}\"\n"
    config_content+="API_TIMEOUT=\"${API_TIMEOUT:-30000}\"\n\n"
    
    # Configurações de Notificações
    config_content+="# Configurações de Notificações\n"
    config_content+="NOTIFICATIONS_ENABLED=\"${NOTIFICATIONS_ENABLED:-true}\"\n"
    config_content+="SMTP_ENABLED=\"${SMTP_ENABLED:-false}\"\n\n"
    
    # Configurações de Manutenção
    config_content+="# Configurações de Manutenção\n"
    config_content+="MAINTENANCE_MODE=\"${MAINTENANCE_MODE:-false}\"\n"
    config_content+="MAINTENANCE_MESSAGE=\"${MAINTENANCE_MESSAGE:-Site em manutenção. Volte em breve.}\"\n\n"
    
    # Configurações de Debug
    config_content+="# Configurações de Debug\n"
    config_content+="DEBUG=\"${DEBUG:-false}\"\n"
    config_content+="VERBOSE_LOGGING=\"${VERBOSE_LOGGING:-false}\"\n\n"
    
    # Configurações de Cluster
    config_content+="# Configurações de Cluster\n"
    config_content+="CLUSTER_MODE=\"${CLUSTER_MODE:-false}\"\n"
    config_content+="MAX_MEMORY=\"${MAX_MEMORY:-1073741824}\"\n\n"
    
    # Configurações de Timeout
    config_content+="# Configurações de Timeout\n"
    config_content+="REQUEST_TIMEOUT=\"${REQUEST_TIMEOUT:-30000}\"\n"
    config_content+="CONNECTION_TIMEOUT=\"${CONNECTION_TIMEOUT:-5000}\"\n\n"
    
    # Configurações de Compressão
    config_content+="# Configurações de Compressão\n"
    config_content+="COMPRESSION_ENABLED=\"${COMPRESSION_ENABLED:-true}\"\n"
    config_content+="COMPRESSION_LEVEL=\"${COMPRESSION_LEVEL:-6}\"\n\n"
    
    # Configurações de Headers de Segurança
    config_content+="# Configurações de Headers de Segurança\n"
    config_content+="SECURITY_HEADERS=\"${SECURITY_HEADERS:-true}\"\n"
    config_content+="XSS_PROTECTION=\"${XSS_PROTECTION:-true}\"\n"
    config_content+="CSRF_PROTECTION=\"${CSRF_PROTECTION:-true}\"\n\n"
    
    # Configurações de CORS
    config_content+="# Configurações de CORS\n"
    config_content+="CORS_ORIGIN=\"${CORS_ORIGIN:-}\"\n"
    config_content+="CORS_CREDENTIALS=\"${CORS_CREDENTIALS:-true}\"\n\n"
    
    # Configurações de Sessão
    config_content+="# Configurações de Sessão\n"
    config_content+="SESSION_SECRET=\"${SESSION_SECRET:-}\"\n"
    config_content+="SESSION_MAX_AGE=\"${SESSION_MAX_AGE:-86400000}\"\n\n"
    
    # Configurações de JWT
    config_content+="# Configurações de JWT\n"
    config_content+="JWT_SECRET=\"${JWT_SECRET:-}\"\n"
    config_content+="JWT_EXPIRES_IN=\"${JWT_EXPIRES_IN:-1h}\"\n\n"
    
    # Configurações de Bcrypt
    config_content+="# Configurações de Bcrypt\n"
    config_content+="BCRYPT_ROUNDS=\"${BCRYPT_ROUNDS:-12}\"\n\n"
    
    # Configurações de Rate Limiting
    config_content+="# Configurações de Rate Limiting\n"
    config_content+="RATE_LIMIT_WINDOW_MS=\"${RATE_LIMIT_WINDOW_MS:-900000}\"\n"
    config_content+="RATE_LIMIT_MAX_REQUESTS=\"${RATE_LIMIT_MAX_REQUESTS:-100}\"\n"
    config_content+="RATE_LIMIT_API=\"${RATE_LIMIT_API:-100}\"\n"
    config_content+="RATE_LIMIT_LOGIN=\"${RATE_LIMIT_LOGIN:-5}\"\n"
    config_content+="RATE_LIMIT_ADMIN=\"${RATE_LIMIT_ADMIN:-20}\"\n\n"
    
    # Configurações de Health Check
    config_content+="# Configurações de Health Check\n"
    config_content+="HEALTH_CHECK_ENABLED=\"${HEALTH_CHECK_ENABLED:-true}\"\n"
    config_content+="METRICS_ENABLED=\"${METRICS_ENABLED:-true}\"\n\n"
    
    # Configurações de Backup Automático
    config_content+="# Configurações de Backup Automático\n"
    config_content+="AUTO_BACKUP_ENABLED=\"${AUTO_BACKUP_ENABLED:-true}\"\n"
    config_content+="AUTO_BACKUP_TIME=\"${AUTO_BACKUP_TIME:-02:00}\"\n"
    config_content+="AUTO_BACKUP_RETENTION=\"${AUTO_BACKUP_RETENTION:-7}\"\n\n"
    
    # Configurações de Notificações por Email
    config_content+="# Configurações de Notificações por Email\n"
    config_content+="NOTIFICATION_EMAIL=\"${NOTIFICATION_EMAIL:-}\"\n\n"
    
    # Salvar arquivo
    echo -e "$config_content" > "$CONFIG_FILE"
    
    # Definir permissões
    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"
    
    print_success "Configuração salva em $CONFIG_FILE"
}

# Função para configurar domínio e email
configure_basic() {
    print_status "📝 Configuração Básica"
    echo ""
    
    # DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        while true; do
            read -p "Digite seu domínio (ex: exemplo.com): " DOMAIN
            if [[ -n "$DOMAIN" ]]; then
                if [[ $DOMAIN =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
                    break
                else
                    print_error "Formato de domínio inválido"
                fi
            else
                print_warning "Domínio é obrigatório"
            fi
        done
    else
        print_status "Domínio atual: $DOMAIN"
        read -p "Alterar domínio? (y/N): " change_domain
        if [[ "$change_domain" == "y" || "$change_domain" == "Y" ]]; then
            while true; do
                read -p "Digite o novo domínio: " DOMAIN
                if [[ -n "$DOMAIN" ]]; then
                    if [[ $DOMAIN =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
                        break
                    else
                        print_error "Formato de domínio inválido"
                    fi
                else
                    print_warning "Domínio é obrigatório"
                fi
            done
        fi
    fi
    
    # EMAIL
    if [[ -z "$EMAIL" ]]; then
        while true; do
            read -p "Digite seu email para notificações: " EMAIL
            if [[ -n "$EMAIL" ]]; then
                if [[ $EMAIL =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                    break
                else
                    print_error "Formato de email inválido"
                fi
            else
                print_warning "Email é obrigatório"
            fi
        done
    else
        print_status "Email atual: $EMAIL"
        read -p "Alterar email? (y/N): " change_email
        if [[ "$change_email" == "y" || "$change_email" == "Y" ]]; then
            while true; do
                read -p "Digite o novo email: " EMAIL
                if [[ -n "$EMAIL" ]]; then
                    if [[ $EMAIL =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                        break
                    else
                        print_error "Formato de email inválido"
                    fi
                else
                    print_warning "Email é obrigatório"
                fi
            done
        fi
    fi
    
    # Configurar CORS_ORIGIN
    CORS_ORIGIN="https://$DOMAIN"
    
    print_success "Configuração básica concluída"
}

# Função para configurar Git
configure_git() {
    print_status "🔧 Configuração do Git"
    echo ""
    
    # GIT_REPOSITORY
    if [[ -z "$GIT_REPOSITORY" ]]; then
        read -p "Digite a URL do repositório Git: " GIT_REPOSITORY
    else
        print_status "Repositório atual: $GIT_REPOSITORY"
        read -p "Alterar repositório? (y/N): " change_repo
        if [[ "$change_repo" == "y" || "$change_repo" == "Y" ]]; then
            read -p "Digite a nova URL do repositório: " GIT_REPOSITORY
        fi
    fi
    
    # GIT_BRANCH
    if [[ -z "$GIT_BRANCH" ]]; then
        read -p "Digite a branch principal (padrão: main): " GIT_BRANCH
        GIT_BRANCH=${GIT_BRANCH:-main}
    else
        print_status "Branch atual: $GIT_BRANCH"
        read -p "Alterar branch? (y/N): " change_branch
        if [[ "$change_branch" == "y" || "$change_branch" == "Y" ]]; then
            read -p "Digite a nova branch: " GIT_BRANCH
        fi
    fi
    
    # GIT_USERNAME (opcional)
    if [[ -z "$GIT_USERNAME" ]]; then
        read -p "Digite seu username do Git (opcional): " GIT_USERNAME
    else
        print_status "Username atual: $GIT_USERNAME"
        read -p "Alterar username? (y/N): " change_username
        if [[ "$change_username" == "y" || "$change_username" == "Y" ]]; then
            read -p "Digite o novo username: " GIT_USERNAME
        fi
    fi
    
    # GIT_TOKEN (opcional)
    if [[ -z "$GIT_TOKEN" ]]; then
        read -p "Digite seu token do Git (opcional): " GIT_TOKEN
    else
        print_status "Token atual: [OCULTO]"
        read -p "Alterar token? (y/N): " change_token
        if [[ "$change_token" == "y" || "$change_token" == "Y" ]]; then
            read -p "Digite o novo token: " GIT_TOKEN
        fi
    fi
    
    print_success "Configuração do Git concluída"
}

# Função para configurar servidor
configure_server() {
    print_status "🖥️ Configuração do Servidor"
    echo ""
    
    # SERVER_IP
    if [[ -z "$SERVER_IP" ]]; then
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
        print_status "IP do servidor detectado: $SERVER_IP"
        read -p "Confirmar IP do servidor? (Y/n): " confirm_ip
        if [[ "$confirm_ip" == "n" || "$confirm_ip" == "N" ]]; then
            read -p "Digite o IP do servidor: " SERVER_IP
        fi
    else
        print_status "IP atual: $SERVER_IP"
        read -p "Alterar IP? (y/N): " change_ip
        if [[ "$change_ip" == "y" || "$change_ip" == "Y" ]]; then
            read -p "Digite o novo IP: " SERVER_IP
        fi
    fi
    
    # SERVER_NAME
    if [[ -z "$SERVER_NAME" ]]; then
        SERVER_NAME=$(hostname)
        print_status "Nome do servidor detectado: $SERVER_NAME"
        read -p "Confirmar nome do servidor? (Y/n): " confirm_name
        if [[ "$confirm_name" == "n" || "$confirm_name" == "N" ]]; then
            read -p "Digite o nome do servidor: " SERVER_NAME
        fi
    else
        print_status "Nome atual: $SERVER_NAME"
        read -p "Alterar nome? (y/N): " change_name
        if [[ "$change_name" == "y" || "$change_name" == "Y" ]]; then
            read -p "Digite o novo nome: " SERVER_NAME
        fi
    fi
    
    print_success "Configuração do servidor concluída"
}

# Função para gerar secrets
generate_secrets() {
    print_status "🔐 Gerando secrets seguros..."
    
    if [[ -z "$JWT_SECRET" ]]; then
        JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
    fi
    
    if [[ -z "$SESSION_SECRET" ]]; then
        SESSION_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
    fi
    
    print_success "Secrets gerados"
}

# Função para mostrar configuração atual
show_config() {
    print_status "📋 Configuração Atual"
    echo ""
    echo "Domínio: ${DOMAIN:-[Não configurado]}"
    echo "Email: ${EMAIL:-[Não configurado]}"
    echo "Repositório Git: ${GIT_REPOSITORY:-[Não configurado]}"
    echo "Branch Git: ${GIT_BRANCH:-main}"
    echo "Username Git: ${GIT_USERNAME:-[Não configurado]}"
    echo "Token Git: ${GIT_TOKEN:+[Configurado]}"
    echo "IP do Servidor: ${SERVER_IP:-[Não configurado]}"
    echo "Nome do Servidor: ${SERVER_NAME:-[Não configurado]}"
    echo "Método de Deploy: ${DEPLOY_METHOD:-git}"
    echo "Backup Habilitado: ${BACKUP_ENABLED:-true}"
    echo "Atualização Automática: ${AUTO_UPDATE:-false}"
    echo ""
}

# Função principal
main() {
    print_status "🔧 Gerenciador de Configurações - Site Novusio"
    echo ""
    
    # Carregar configuração existente
    load_config
    
    while true; do
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "1. 📝 Configurar Básico (Domínio e Email)"
        echo "2. 🔧 Configurar Git"
        echo "3. 🖥️ Configurar Servidor"
        echo "4. 📋 Mostrar Configuração Atual"
        echo "5. 💾 Salvar Configuração"
        echo "6. 🔐 Gerar Secrets"
        echo "0. 🚪 Sair"
        echo ""
        read -p "Opção: " option
        
        case $option in
            1)
                configure_basic
                ;;
            2)
                configure_git
                ;;
            3)
                configure_server
                ;;
            4)
                show_config
                ;;
            5)
                generate_secrets
                save_config
                ;;
            6)
                generate_secrets
                print_success "Secrets gerados"
                ;;
            0)
                print_status "Saindo..."
                exit 0
                ;;
            *)
                print_error "Opção inválida"
                ;;
        esac
        
        echo ""
    done
}

# Executar função principal
main "$@"
